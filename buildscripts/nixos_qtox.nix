let
  overlay = final: prev:
    # a fixed point overay for overriding a package set

    with final; {
      # use the final result of the overlay for scope

      libtoxcore =
        # build a custom libtoxcore
        prev.libtoxcore.overrideAttrs ({ ... }: {
          src = fetchFromGitHub {
            owner = "zoff99";
            repo = "c-toxcore";
            rev = "580fb5369ddf32e0302b4eba1344a72ddc13bfa4";
            fetchSubmodules = true;
            sha256 = "sha256-xKG0F6LlCjCWt1YrAMGdqI9WV5NBEjs6+FbApEa1w8I=";
          };
          patches = [
            (fetchpatch {
              url =
                "https://raw.githubusercontent.com/Zoxcore/qTox_enhanced/zoxcore/push_notification/buildscripts/patches/tc___ftv2_capabilities.patch";
              sha256 = "sha256-JThBGKgpLKQTLYCWpTyWPPaZ2WuyTA6N8BXeh8+e7g0=";
            })
          ];
          buildInputs = [
            libsodium msgpack ncurses libconfig
            libopus libvpx x264 ffmpeg
          ];
        });

      toxext =
        # use an existing package or package it here
        prev.toxext or stdenv.mkDerivation rec {
          pname = "toxext";
          version = "0.0.3";
          src = fetchFromGitHub {
            owner = pname;
            repo = pname;
            rev = "v${version}";
            hash = "sha256-I0Ay3XNf0sxDoPFBH8dx1ywzj96Vnkqzlu1xXsxmI1M=";
          };
          nativeBuildInputs = [ cmake pkg-config ];
          buildInputs = [ libtoxcore ];
        };

      toxextMessages =
        # use an existing package or package it here
        prev.toxextMessages or stdenv.mkDerivation rec {
          pname = "tox_extension_messages";
          version = "0.0.3";
          src = fetchFromGitHub {
            owner = "toxext";
            repo = pname;
            rev = "v${version}";
            hash = "sha256-qtjtEsvNcCArYW/Zyr1c0f4du7r/WJKNR96q7XLxeoA=";
          };
          nativeBuildInputs = [ cmake pkg-config ];
          buildInputs = [ libtoxcore toxext ];
        };

      qtox = prev.qtox.overrideAttrs ({ buildInputs, ... }: {
        version = "push_notification-";
        # take sources directly from this repo checkout
        buildInputs = buildInputs ++ [ curl libtoxcore toxext toxextMessages ];
      });

    };

in { pkgs ? import <nixpkgs> { } }:
# take nixpkgs from the environment
let
  pkgs' = pkgs.extend overlay;
  # apply overlay
in pkgs'.qtox
# select package
