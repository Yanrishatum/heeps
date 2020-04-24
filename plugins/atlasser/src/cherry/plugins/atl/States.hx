package cherry.plugins.atl;

enum CurrentAction {
  None;
  Create;
  Drag;
}

enum CornerType {
  TopLeft;
  TopRight;
  BottomLeft;
  BottomRight;
  Center;
  Top;
  Left;
  Right;
  Bottom;
}

enum DragRestrict {
  None; // No drag restraints
  NoneSnap; // No restraints + shift auto-restraint
  NoneAngle;
  Diagonal;
  DiagonalSnap;
  Vertical;
  Horizontal;
}
