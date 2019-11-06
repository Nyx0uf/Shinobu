#!/usr/bin/env python3
# coding: utf-8

"""
read the mpd music directory to get albums, paths, albumartist, genre, year and create a json file
* Only supports FLAC / MP3 / M4A (ALAC / AAC)
* pip install mutagen
"""

import os
import sys
import argparse
import multiprocessing
import threading
import queue
import json
from typing import List
import mutagen
import mutagen.mp3
import mutagen.easymp4

class Album:
    """Very small representation of an album"""
    def __init__(self, song: str, fullpath: str, songpath: str):
        self.name = ""
        self.path = str(songpath.replace(fullpath, ""))
        self.year = None
        self.genre = None
        self.artist = None
        if self.path[0] != "/":
            self.path = f"/{self.path}"

        if song.endswith(".mp3"):
            infos = mutagen.mp3.EasyMP3(song)
        elif song.endswith(".m4a"):
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

def walk_directory(path: str) -> queue.Queue:
    """walk directory at `path`"""
    ret = queue.Queue()
    for root, _, files in os.walk(path):
        for f in files:
            path = os.path.join(root, f)
            _, ext = os.path.splitext(path)
            if ext in [".flac", ".m4a", ".mp3"]:
                ret.put(path)
    return ret

def albums_from_songs(queue: queue.Queue, albums: List[Album], done: List[str], fullpath: str):
    """Create an album from a song file"""
    while queue.empty() is False:
        infile = queue.get()
        song_path = os.path.dirname(infile)
        if song_path not in done:
            alb = Album(infile, fullpath, song_path)
            albums.append(alb)
            done.append(song_path)
        queue.task_done()

def json_dump(path: str, albums: List[Album]):
    """Dumps `albums` in _mpd.json at `path`"""
    with open(os.path.join(path, "_mpd.json"), 'w') as outfile:
        json.dump([a.__dict__ for a in albums], outfile)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", action="store", dest="d", type=str, default=None, help="MPD directory (same as music_directory in mpd config file)")
    args = parser.parse_args()

    # Sanity checks
    if args.d is None or os.path.isdir(args.d) is False:
        print(f"Invalid argument : {args.d}")
        sys.exit(-1)

    # Get all songs
    songs_queue = walk_directory(os.path.abspath(args.d))

    # Create albums from songs
    albums_dup: List[Album] = []
    paths_done: List[str] = []
    for i in range(multiprocessing.cpu_count()):
        th = threading.Thread(target=albums_from_songs, args=(songs_queue, albums_dup, paths_done, args.d,))
        th.daemon = True
        th.start()
    songs_queue.join()
    # Make unique
    albums: List[Album] = list(dict.fromkeys(albums_dup))

    # Save as json
    json_dump(args.d, albums)
