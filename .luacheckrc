std = "luajit"

globals = {
  "playdate",
  "import",
  "class",
  "Object",
  "kTextAlignment",
}

ignore = {
  "122", -- Setting a read-only field of a global variable (needed for Playdate callbacks).
  "212", -- Unused argument — _arg_name convention is clearer than bare _ in callbacks.
  "631", -- Line too long — allowed for URLs and similar.
}
