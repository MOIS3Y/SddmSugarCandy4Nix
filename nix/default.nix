{ stdenv
,lib
,coreutils
,sddm
,qtbase
,qtsvg
,qtquickcontrols2
,qtgraphicaleffects
,writeTextFile
,settings ? {}
, ... 
}: let
  customToINI = with lib; generators.toINI {
    # specifies how to format a key/value pair
    mkKeyValue = generators.mkKeyValueDefault {
      # specifies the generated string for a subset of nix values
      mkValueString = v:
        if v == true then ''"true"''
        else if v == false then ''"false"''
        else if isString v then ''"${v}"''
        # and delegates all other values to the default generator
        else generators.mkValueStringDefault {} v;
    } "=";
  };
  defaultConfig = {
    Background="Backgrounds/Mountain.jpg";
    DimBackgroundImage="0.0";
    ScaleImageCropped=true;
    ScreenWidth="1440";
    ScreenHeight="900";
    FullBlur=false;
    PartialBlur=true;
    BlurRadius="100";
    HaveFormBackground=false;
    FormPosition="left";
    BackgroundImageHAlignment="center";
    BackgroundImageVAlignment="center";
    MainColor="white";
    AccentColor="#fb884f";
    BackgroundColor="#444";
    OverrideLoginButtonTextColor="";
    InterfaceShadowSize="6";
    InterfaceShadowOpacity="0.6";
    RoundCorners="20";
    ScreenPadding="0";
    Font="Noto Sans";
    FontSize="";
    ForceRightToLeft=false;
    ForceLastUser=true;
    ForcePasswordFocus=true;
    ForceHideCompletePassword=false;
    ForceHideVirtualKeyboardButton=false;
    ForceHideSystemButtons=false;
    AllowEmptyPassword=false;
    AllowBadUsernames=false;
    Locale="";
    HourFormat="HH:mm";
    DateFormat="dddd, d of MMMM";
    HeaderText="Welcome!";
    TranslatePlaceholderUsername="";
    TranslatePlaceholderPassword="";
    TranslateShowPassword="";
    TranslateLogin="";
    TranslateLoginFailedWarning="";
    TranslateCapslockWarning="";
    TranslateSession="";
    TranslateSuspend="";
    TranslateHibernate="";
    TranslateReboot="";
    TranslateShutdown="";
    TranslateVirtualKeyboardButton="";
  };
  overrideConfig = settings;
  # merge default and user settings:
  customConfig = {
    General = (lib.attrsets.overrideExisting defaultConfig overrideConfig);
  };
  # parse customConfig to INI file:
  cfgText = customToINI customConfig;
  cfgFile = writeTextFile {
    name = "theme.conf.user";
    text = ''
      ${cfgText}
    '';
  };
in stdenv.mkDerivation {
  pname = "SddmSugarCandy4Nix";
  version = "1.6";
  dontWrapQtApps = true;
  userConfig = cfgFile;
  src = ../src;
  
  propagatedUserEnvPkgs = [
    sddm
    qtbase
    qtsvg
    qtgraphicaleffects
    qtquickcontrols2
  ];

  nativeBuildInputs = [
    coreutils
  ];

  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
    cp $userConfig $out/theme.conf.user
  '';
  onCheck = false;
}
