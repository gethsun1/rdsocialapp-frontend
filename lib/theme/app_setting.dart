enum Font {
  lato,
  openSans,
  poppins,
  raleway,
  roboto
}

enum DisplayMode{
  light,
  dark
}

class AppSetting{
  static DisplayMode mode = DisplayMode.light;

  static void setDisplayMode(DisplayMode currentMode){
    mode = currentMode;
  }

}