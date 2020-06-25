#!/usr/bin/env python3
# coding: utf-8

"""
read the mpd music directory to get albums, paths, albumartist, genre, year and create a json file
* Only supports AAC / ALAC / FLAC / MP3
* pip(3) install mutagen
"""

import os
import sys
import argparse
import multiprocessing
import threading
import queue
import json
from pathlib import Path
from typing import List
import mutagen
import mutagen.mp3
import mutagen.easymp4

class Album:
    """Very small representation of an album"""
    def __init__(self, song: Path, fullpath: Path, songpath: Path):
        self.name = ""
        self.path = str(songpath).replace(str(fullpath), "")
        self.year = None
        self.genre = None
        self.artist = None
        if self.path[0] != "/":
            self.path = f"/{self.path}"

        if song.suffix == ".mp3":
            infos = mutagen.mp3.EasyMP3(song)
        elif song.suffix == ".m4a":
            infos = mutagen.easymp4.EasyMP4(song)
        else:
            infos = mutagen.File(song)

        if infos is not None:
            try:
                if "album" in infos:
                    album_name = infos["album"]
                    if album_name is not None and album_name:
                        self.name = str(album_name[0])
                if "genre" in infos:
                    album_genre = infos["genre"]
                    if album_genre is not None and album_genre:
                        self.genre = str(album_genre[0])
                if "albumartist" in infos:
                    album_artist = infos["albumartist"]
                    if album_artist is not None and album_artist:
                        self.artist = str(album_artist[0])
                if "date" in infos:
                    album_year = infos["date"]
                    if album_year is not None and album_year:
                        self.year = str(str(album_year[0]).split('-')[0])
            except:
                print(f"{self.path}\n---{infos}\n---\n")

    def __str__(self):
        return f"{self.name}|{self.path}"

    def __repr__(self):
        return f"{self.name}|{self.path}"

    def __eq__(self, other):
        return self.name == other.name and self.path == other.path

    def __hash__(self):
        return hash(self.name + self.path)

def walk_directory(path: Path, allowed_suffixes=[".flac", ".m4a", ".mp3"]) -> queue.Queue:
    """walk directory at `path`"""
    ret = queue.Queue()
    for root, _, files in os.walk(path):
        for f in files:
            p = Path(root) / f
            if p.suffix in allowed_suffixes:
                ret.put(p)
    return ret

def albums_from_songs(queue: queue.Queue, albums: List[Album], done: List[Path], fullpath: Path):
    """Create an album from a song file"""
    while queue.empty() is False:
        infile: Path = queue.get()
        song_path = infile.parent
        if song_path not in done:
            alb = Album(infile, fullpath, song_path)
            albums.append(alb)
            done.append(song_path)
        queue.task_done()

def json_dump(path: Path, albums: List[Album]):
    """Dumps `albums` in _mpd.json at `path`"""
    with open(path, 'w') as outfile:
        json.dump([a.__dict__ for a in albums], outfile)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("mpd_directory", type=Path, help="MPD directory (same as music_directory in mpd config file)")
    args = parser.parse_args()

    # Sanity checks
    path = args.mpd_directory.resolve()
    if path.exists() is False or path.is_dir() is False:
        print(f"[!] Invalid argument : {path}")
        sys.exit(-1)

    # Get all songs
    songs_queue = walk_directory(path)

    # Create albums from songs
    albums_dup: List[Album] = []
    paths_done: List[Path] = []
    for i in range(multiprocessing.cpu_count()):
        th = threading.Thread(target=albums_from_songs, daemon=True, args=(songs_queue, albums_dup, paths_done, path,))
        th.start()
    songs_queue.join()

    # Make unique
    albums: List[Album] = list(dict.fromkeys(albums_dup))

    # Save as json
    json_dump(path / "_mpd.json", albums)
