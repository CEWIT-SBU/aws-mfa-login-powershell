# Parameters
Param(
  [String]$region = $null,
  
  [Alias('device-arn')]
  $deviceArn = $null,
  
  [String]$token = $null
)

# Validation Functions
function isValidRegion($region){
  $validRegions =
    "us-east-1",
    "us-east-2",
    "us-west-1",
    "us-west-2",
    "ca-central-1",
    "eu-west-1",
    "eu-central-1",
    "eu-west-2",
    "ap-northeast-1",
    "ap-northeast-2",
    "ap-southeast-1",
    "ap-southeast-2",
    "ap-south-1",
    "sa-east-1"
  foreach($validRegion in $validRegions){
    if($region -Eq $validRegion){return $TRUE}
  }
  return $FALSE
}

function isValidDeviceArn($arn){
  #Note: This is PS is case insensitive by default.
  return $($arn -match 'arn:aws:iam::[0-9]{12}:mfa/[a-zA-Z_0-9]+')
}

function isValidToken($token){
  return $($token -match '^[0-9]{1,6}$')
}

### BEGIN SCRIPT ###

# Validate Parameters
if($region){
  if(!(isValidRegion($region))){
    Write-Host "Bad region name."
    exit
  }
}
if($deviceArn){
  if(!(isValidDeviceArn($deviceArn))){
    Write-Host "Bad device ARN is not formatted correctly."
    exit
  }
}
if($token){
  if(!(isValidToken($token))){
    Write-Host "Bad Token.  Must be exactly 6 digits."
    exit
  }
}

#If Region is not a parameter ask for it
if(!$region){

  #Get the Environment default if it exists
  $defaultRegion =
    if(Test-Path env:AWS_DEFAULT_REGION){
      $Env:AWS_DEFAULT_REGION
    }else{
      'us-east-1'
    }
  
  #Ask for region
  $userResponce = Read-Host "Region [$defaultRegion]"
  
  #Handle Responce
  if($userResponce){
    if((isValidRegion($userResponce))){
      $region = $userResponce
    }else{
      Write-Host "Invalid Region."
      exit
    }
  }else{
    $region = $defaultRegion
  }
}

#If Device ARN is not a parameter ask for it
if(!$deviceArn){
  
  #Get the Environment default if it exists
  $defaultDeviceArn =
    if(Test-Path env:AWS_MFA_DEVICE_ARN){
      $Env:AWS_MFA_DEVICE_ARN
    }
  
  #Ask for ARN
  $userResponce = Read-Host "Device ARN [$defaultDeviceArn]"
  
  #Handle Responce
  if($userResponce){
    if((isValidDeviceArn($userResponce))){
      $deviceArn = $userResponce
    }else{
      Write-Host "Invalid ARN."
      exit
    }
  }else{
    if (!$defaultDeviceArn){
      Write-Host "You must define a Device ARN. There is no default."
      exit
    }
    $deviceArn = $defaultDeviceArn
  }
}

#If Token is not a parameter ask for it
if(!$token){
  $userResponce = Read-Host 'Token(6-digits)'
  
  #Handle Responce
  if((isValidToken($userResponce))){
    $token = $userResponce
  }else{
    Write-Host "Invalid Token."
    exit
  }
}

$Credentials = aws sts get-session-token --serial-number $deviceArn --token-code $token --output json | ConvertFrom-Json

if(!$?){
  Write-Host "A GetSessionToken error is likely because you already have an AWS session."
  Write-Host "You should be able to run AWS commands."
  Write-Host "If not, exit this terminal, start a new one, and retry."
  exit
}

$Env:AWS_ACCESS_KEY_ID = $Credentials.Credentials.AccessKeyId
$Env:AWS_SECRET_ACCESS_KEY = $Credentials.Credentials.SecretAccessKey
$Env:AWS_SESSION_TOKEN = $Credentials.Credentials.SessionToken
$Env:AWS_DEFAULT_REGION = $region
