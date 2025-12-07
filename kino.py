#!/usr/bin/env python3

# TODO command to take all video in order and put them in a reveal js
#  typst query --root . --input fps=1 examples/ex.typ metadata --field value | jq
# ffmpeg -pattern_type glob -i "*.png" -vf "select='gte(n,2)'" -frames:v 2 -r 3 output.mp4


import argparse
import os
import sys
import subprocess
import shutil
import tempfile
import json

def assert_installed(program: str):
    if shutil.which(program) is None:
        raise RuntimeError(f"Failed to run {program}. Is {program} installed?")

def create_parser():
    parser = argparse.ArgumentParser(
        description="Utility for creating animations",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog="""
Examples:
  kino.py slides
  kino.py --timeout 20 slides
  kino.py video --cut none --fps 24 --ppi 150
  kino.py --root ./project revealjs --cut scene
"""
    )
    parser.add_argument(
        "--root",
        help="Typst root directory"
    )

    parser.add_argument(
        "--timeout",
        type=int,
        default=30,
        help="timeout (default: 30s)"
    )

    parser.add_argument(
        "input",
        help="input Typst file",
    )
    
    # Create subparsers for different commands
    subparsers = parser.add_subparsers(
        dest="output format",
        help="output format",
        metavar="ouput",
        required=True
    )

    # create parent parser
    parent_parser = argparse.ArgumentParser(add_help=False)
    
    # =====================
    # slides subcommand
    # =====================
    slides_parser = subparsers.add_parser(
        "slides",
        help="pdf output",
        parents=[parent_parser]
    )

    # create subparent parser
    subparent_parser = argparse.ArgumentParser(add_help=False)

    subparent_parser.add_argument(
        "--cut",
        choices=["all", "none", "scene"],
        default="all",
        help="cuts to consider (default: all)"
    )
    
    subparent_parser.add_argument(
        "--fps",
        type=int,
        default=30,
        help="frames per second (default: 30)"
    )
    
    subparent_parser.add_argument(
        "--ppi",
        type=int,
        default=144,
        help="pixels per inch (default: 144)"
    )
    
    slides_parser.set_defaults(func=handle_slides)
    
    # =====================
    # video subcommand
    # =====================
    video_parser = subparsers.add_parser(
        "video",
        help="video output",
        parents=[subparent_parser]
    )
    
    video_parser.add_argument(
        "--format",
        type=str,
        default="mp4",
        help="ouput video format (default: mp4)"
    )
    
    video_parser.set_defaults(func=handle_video)
    
    # =====================
    # revealjs subcommand
    # =====================
    revealjs_parser = subparsers.add_parser(
        "revealjs",
        help="reveal.js output",
        parents=[subparent_parser]
    )

    revealjs_parser.set_defaults(func=handle_revealjs)
    
    return parser

def handle_slides(args):
    """Handle slides subcommand"""
    
    assert_installed("typst")

    cmd = ["typst", "compile", args.input, "--input", "fps=0"]
    if args.root is not None:
        cmd += ["--root", os.path.abspath(args.root)]

    try:    
        subprocess.run(cmd, timeout = args.timeout)
        
    except subprocess.TimeoutExpired:
        print(f"Timeout after {args.timeout} seconds.\nhint: timeout can be increased using the --timeout option.")
        return 124
        
    except Exception as e:
        print(f"Unexpected error: {e}")
        return 1
    
    return 0

def handle_video(args):
    """Handle video subcommand"""

    assert_installed("typst")
    assert_installed("ffmpeg")

    rootpath, _ = os.path.splitext(args.input)
    output = f"{rootpath}.{args.format}"
    
    with tempfile.TemporaryDirectory() as tmpdir:

        cmd1 = [
            "typst",
            "compile",
            "--input", f"fps={args.fps}",
            args.input,
            os.path.join(tmpdir, "output{0p}.png"),
            "--ppi", f"{args.ppi}"
        ]
        if args.root is not None:
            cmd1 += ["--root", os.path.abspath(args.root)] 

        try:    
            subprocess.run(cmd1, timeout = args.timeout, check = True)

            if args.cut == "none":
                cmd2 = [
                    "ffmpeg",
                    "-y",
                    "-loglevel", "error",
                    "-r", f"{args.fps}",
                    "-pattern_type", "glob", 
                    "-i", f"{os.path.join(tmpdir, "output*.png")}",
                    "-r", f"{args.fps}",
                    output
                ]

                subprocess.run(cmd2, timeout = args.timeout)

            elif args.cut == "all":
                cmd2 = [
                    "typst",
                    "query",
                    args.input,
                    "--input", f"fps={args.fps}",
                    "--input", "query=1",
                    "metadata", 
                    "--field", "value"
                ]
                if args.root is not None:
                    cmd2 += ["--root", os.path.abspath(args.root)] 

                result = subprocess.run(cmd2, timeout = args.timeout, capture_output=True, text=True, check = True)
                data = json.loads(result.stdout)

                # Generate ffmpeg commands
                ffmpeg_commands = []
                for item in data:
                    output = f"{rootpath}{item['segment']}.{args.format}"
                    cmd = [
                        "ffmpeg",
                        "-y",                        
                        "-loglevel", "error",
                        "-r", str(item['fps']),
                        "-pattern_type", "glob",
                        "-i", f"{os.path.join(tmpdir, "output*.png")}",
                        "-vf", f"select='gte(n,{item['from']})'",
                        "-frames:v", str(item['frames']),
                        "-r", str(item['fps']),
                        output
                    ]
                    ffmpeg_commands.append(cmd)

                    result = subprocess.run(cmd, timeout = args.timeout, check = True)
                         
        except subprocess.TimeoutExpired:
            print(f"Timeout after {args.timeout} seconds.\nhint: timeout can be increased using the --timeout option.")
            return 124

        except subprocess.CalledProcessError:
            print("The above exception was raised during conversion.")
        
        except Exception as e:
            print(f"Unexpected error: {e}")
            return 1

        return 0

def handle_revealjs(args):
    """Handle revealjs subcommand"""
    
    return 0

def main():
    parser = create_parser()
    pargs = parser.parse_args()
    return pargs.func(pargs)

if __name__ == "__main__":
    sys.exit(main())
