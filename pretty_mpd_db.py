#!/usr/bin/env python3
# coding: utf-8

# pylint: disable=line-too-long

"""
Create a JSON file containing all MPD albums
[{
    name:'ALBUM NAME',
    path:'ALBUM PATH'
}]
"""

import os
import sys
import argparse
import multiprocessing
import threading
import queue
import json
import mutagen
import mutagen.mp3
import mutagen.easymp4


class Album:
    """Very small representation of an album"""
    def __init__(self, p_song, p_fullpath, p_songpath):
        self.name = ''
        self.path = '/' + str(p_songpath.replace(p_fullpath, ''))
        self.year = None
        self.genre = None
        self.artist = None

        if p_song.endswith('.mp3'):
            infos = mutagen.mp3.EasyMP3(p_song)
        elif p_song.endswith('.m4a'):
            infos = mutagen.easymp4.EasyMP4(p_song)
        else:
            infos = mutagen.File(p_song)
        if infos is not None and infos['album']:
            album_name = infos['album']
            if album_name is not None and album_name:
                self.name = str(album_name[0])
            album_genre = infos['genre']
            if album_genre is not None and album_genre:
                self.genre = str(album_genre[0])
            album_artist = infos['albumartist']
            if album_artist is not None and album_artist:
                self.artist = str(album_artist[0])
            album_year = infos['date']
            if album_year is not None and album_year:
                self.year = str(str(album_year[0]).split('-')[0])


    def __str__(self):
        return '{}|{}'.format(self.name, self.path)

    def __repr__(self):
        return '{}|{}'.format(self.name, self.path)

    def __eq__(self, p_other):
        return self.name == p_other.name and self.path == p_other.path

    def __hash__(self):
        return hash(self.name + self.path)

def walk_directory(p_path):
    """walk a directory"""
    ret = queue.Queue()
    for root, _, files in os.walk(p_path):
        for file in files:
            path = os.path.join(root, file)
            _, ext = os.path.splitext(path)
            if ext in ['.flac', '.m4a', '.mp3']:
                ret.put(path)
    return ret

def albums_from_songs(p_queue, p_albums, p_done, p_fullpath):
    """Create an album from a song file"""
    while p_queue.empty() is False:
        infile = p_queue.get()
        song_path = os.path.dirname(infile)
        if song_path not in p_done:
            alb = Album(infile, p_fullpath, song_path)
            p_albums.append(alb)
            p_done.append(song_path)
        p_queue.task_done()

if __name__ == '__main__':
    PARSER = argparse.ArgumentParser()
    PARSER.add_argument('-d', action='store', dest='d', type=str, help='MPD directory (same as music_directory in mpd config file)')
    RES = PARSER.parse_args()

    # Sanity checks
    if RES.d is None or os.path.isdir(RES.d) is False:
        sys.exit(-1)

    # Get all songs
    SONGS = walk_directory(os.path.abspath(RES.d))

    # Create albums from songs
    ALBUMS_DUP = list()
    PATHS_DONE = list()
    for i in range(multiprocessing.cpu_count()):
        th = threading.Thread(target=albums_from_songs, args=(SONGS, ALBUMS_DUP, PATHS_DONE, RES.d,))
        th.daemon = True
        th.start()
    SONGS.join()
    # Make unique
    ALBUMS = list(dict.fromkeys(ALBUMS_DUP))

    with open('{}_mpd.json'.format(RES.d), 'w') as outfile:
        json.dump([a.__dict__ for a in ALBUMS], outfile)
