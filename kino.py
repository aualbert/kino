#!/usr/bin/env python3

# ❯ typst compile --root . examples/ex.typ --input fps=10 output/{0p}.png
# typst query --root . examples/ex.typ --input fps=10 metadata --field value | jq -r '.[] | "ffmpeg -y -pattern_type glob -i \"output/*.png\" -vf \"select='"'"'gte(n,\(.from))'"'"'\" -frames:v \(.frames) -r \(.fps) output/\(.segment).mp4"' | while read cmd; do
# 	eval "$cmd"
# done
# TODO input option for faster query 
# TODO command to take all video in order and put them in a reveal js
#  typst query --root . --input fps=1 examples/ex.typ metadata --field value | jq
# ffmpeg -pattern_type glob -i "*.png" -vf "select='gte(n,2)'" -frames:v 2 -r 3 output.mp4


import argparse
import os
import sys
import subprocess
import shutil
import tempfile

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
    if not args.root is None:
        cmd += ["--root", os.path.abspath(args.root)]
        
    result = subprocess.run(cmd, timeout = args.timeout)
    
    return result.returncode

def handle_video(args):
    """Handle video subcommand"""

    assert_installed("typst")
    assert_installed("jq")
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
        if not args.root is None:
            cmd1 += ["--root", os.path.abspath(args.root)]    

        if args.cut == "none":
            cmd2 = [
                "ffmpeg",
                "-y",
                "-r", f"{args.fps}",
                "-pattern_type", "glob", 
                "-i", f"{os.path.join(tmpdir, "output*.png")}",
                "-r", f"{args.fps}",
                output
            ]
        else:
            cmd2 = [
                "ffmpeg",
                "-h"
            ] #TODO
        
        result = subprocess.run(cmd1, timeout = args.timeout)    
        if result.returncode != 0:
            return result
        
        result = subprocess.run(cmd2, timeout = args.timeout, capture_output=True)
    
    return 0

def handle_revealjs(args):
    """Handle revealjs subcommand"""
    
    print(f"Generating reveal.js presentation...")
    print(f"  Root directory: {root_path}")
    print(f"  Cut mode: {args.cut}")
    print(f"  FPS: {args.fps}")
    print(f"  DPI: {args.ppi}")
    
    # Add your reveal.js generation logic here
    # For example:
    # generate_revealjs(root_path, cut_mode=args.cut, fps=args.fps, dpi=args.dpi)
    
    return 0

def main():
    parser = create_parser()
    pargs = parser.parse_args()
    return pargs.func(pargs)

if __name__ == "__main__":
    sys.exit(main())
