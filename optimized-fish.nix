pkgs: pkgs.fish.overrideAttrs (oldAttrs: {
  # We clear RUSTFLAGS entirely to prevent macro compiler collisions
  RUSTFLAGS = "";

  # We pass the optimizations directly to Cargo's build profile configuration.
  # This guarantees LTO is only applied to the final binary, bypassing the macro crates completely.
  CARGO_PROFILE_RELEASE_LTO = "fat";
  CARGO_PROFILE_RELEASE_CODEGEN_UNITS = 1;
  CARGO_PROFILE_RELEASE_PANIC = "abort";

  # We can safely pass the native CPU micro-targeting directly via the wrapper
  # because target-cpu does not cause proc-macro LTO mismatches.
  NIX_RUSTFLAGS = "-C target-cpu=native";

  cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [ "-DCMAKE_BUILD_TYPE=Release" ];
})
