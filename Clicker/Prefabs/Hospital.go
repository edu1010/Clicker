components {
  id: "BuildingsIncrement"
  component: "/Scripts/BuildingsIncrement.script"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
  properties {
    id: "incrementValue"
    value: "50.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "spriteHospital"
  type: "sprite"
  data: "tile_set: \"/Atlas/Buildings.atlas\"\n"
  "default_animation: \"Hospital\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  ""
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
