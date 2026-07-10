-- NVIDIA Environment Configs

-- Variables
local env = hl.env

env("AQ_NO_MODIFIERS",           "1")
env("LIBVA_DRIVER_NAME",         "nvidia")
env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
env("GBM_BACKEND",               "nvidia-drm")
