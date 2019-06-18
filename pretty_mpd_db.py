#!/usr/bin/env python3
# coding: utf-8

# pylint: disable=line-too-long

"""
Create a JSON file or sqlite3 DB containing all MPD albums
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
import sqlite3
import mutagen
import mutagen.mp3
import mutagen.easymp4


class Album:
    """Very small representation of an album"""
    def __init__(self, p_song, p_fullpath, p_songpath):
        self.name = ''
        self.path = '/' + str(p_songpath.replace(p_fullpath, ''))

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
    PARSER.add_argument('-fmt', action='store', dest='fmt', type=str, default='json', help='format')
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

    if RES.fmt.lower() == 'sqlite':
        CONNECTION = sqlite3.connect('{}_mpd.db'.format(RES.d))
        CURSOR = CONNECTION.cursor()
        CURSOR.execute('CREATE TABLE IF NOT EXISTS albums(id INTEGER PRIMARY KEY, name TEXT NOT NULL, path TEXT NOT NULL)')
        for album in ALBUMS:
            CURSOR.execute('INSERT INTO albums(name, path) VALUES(?, ?)', (album.name, album.path,))
        CONNECTION.commit()
        CONNECTION.close()
    else:
        with open('{}_mpd.json'.format(RES.d), 'w') as outfile:
            json.dump([a.__dict__ for a in ALBUMS], outfile)
