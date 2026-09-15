/// Shared size scale for the button system — matches the "Button Sizes"
/// reference: Small 32px, Medium 40px, Large 48px, XL 56px.
enum AppButtonSize { small, medium, large, xl }

extension AppButtonSizeX on AppButtonSize {
  double get height {
    switch (this) {
      case AppButtonSize.small:
        return 32;
      case AppButtonSize.medium:
        return 40;
      case AppButtonSize.large:
        return 48;
      case AppButtonSize.xl:
        return 56;
    }
  }

  double get horizontalPadding {
    switch (this) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 22;
      case AppButtonSize.xl:
        return 26;
    }
  }

  double get fontSize {
    switch (this) {
      case AppButtonSize.small:
        return 12;
      case AppButtonSize.medium:
        return 13;
      case AppButtonSize.large:
        return 15;
      case AppButtonSize.xl:
        return 16;
    }
  }

  double get iconSize {
    switch (this) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 16;
      case AppButtonSize.large:
        return 18;
      case AppButtonSize.xl:
        return 20;
    }
  }

  double get iconGap {
    switch (this) {
      case AppButtonSize.small:
        return 6;
      case AppButtonSize.medium:
        return 6;
      case AppButtonSize.large:
        return 8;
      case AppButtonSize.xl:
        return 8;
    }
  }
}
