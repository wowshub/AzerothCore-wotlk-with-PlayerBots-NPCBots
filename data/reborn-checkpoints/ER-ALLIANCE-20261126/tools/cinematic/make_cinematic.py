# -*- coding: utf-8 -*-
"""Retail movie -> AVI that the 3.3.5 client plays.

  python make_cinematic.py MOVIE_ID OutputName --work DIR [--probe EXE] [--ini PROBE.ini]

DIR must hold Movie.csv and MovieVariation.csv (https://wago.tools/db2/Movie/csv , .../MovieVariation/csv).
Every video variant of the movie is tried (some are not in the local retail data); the first readable one is used.
Writes DIR/<OutputName>.avi and DIR/<OutputName>_frames.png (look at it: is this the right movie?).
Needs ffmpeg / ffprobe on PATH, RetailAssetProbe.exe and a probe ini with mode=local pointing at a local retail install.
"""
import argparse, csv, os, subprocess, sys

DEF_PROBE = r'D:\_zsdc\home64f\w\build-x64\Release\RetailAssetProbe.exe'
DEF_INI = r'D:\_zsdc\vm12175\probe.ini'


def table(work, name):
    with open(os.path.join(work, name), newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f))


def main():
    a = argparse.ArgumentParser()
    a.add_argument('movie_id')
    a.add_argument('name')
    a.add_argument('--work', required=True)
    a.add_argument('--probe', default=DEF_PROBE)
    a.add_argument('--ini', default=DEF_INI)
    o = a.parse_args()
    work = os.path.abspath(o.work)
    movie = [r for r in table(work, 'Movie.csv') if r['ID'] == o.movie_id]
    assert len(movie) == 1, 'movie id not in Movie.csv'
    audio = movie[0]['AudioFileDataID']
    variants = [r['FileDataID'] for r in table(work, 'MovieVariation.csv') if r['MovieID'] == o.movie_id]
    print('movie', o.movie_id, 'audio', audio, 'video variants', variants)
    assert variants, 'no variant'
    out = os.path.join(work, 'raw')
    os.makedirs(out, exist_ok=True)
    wanted = ['retail/%s.avi' % v for v in variants] + ['retail/%s.mp3' % audio]
    lst = os.path.join(work, 'movie.lst')
    open(lst, 'w', newline='\n').write('\n'.join(wanted) + '\n')
    r = subprocess.run([o.probe, o.ini, '--extract-batch', lst, out], capture_output=True, text=True, errors='replace')
    print((r.stdout + r.stderr).strip())
    video = next((os.path.join(out, '%s.avi' % v) for v in variants if os.path.exists(os.path.join(out, '%s.avi' % v))), None)
    sound = os.path.join(out, '%s.mp3' % audio)
    assert video, 'no readable video variant (CascLib error 2 = not downloaded locally, 1392 = missing data or encryption key)'
    assert os.path.exists(sound), 'audio not readable'
    frames = os.path.join(work, o.name + '_frames.png')
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', video, '-vf', 'fps=1/3,scale=426:240,tile=3x3', '-frames:v', '1', frames], check=True)
    avi = os.path.join(work, o.name + '.avi')
    # DIVX tag, 1024x576, 30 fps, no B-frames, MP3 44.1 kHz: the form that played in this client
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', video, '-i', sound, '-map', '0:v:0', '-map', '1:a:0', '-c:v', 'mpeg4', '-vtag', 'DIVX',
                    '-bf', '0', '-g', '30', '-q:v', '4', '-vf', 'scale=1024:576,setsar=1', '-r', '30', '-c:a', 'libmp3lame', '-b:a', '128k',
                    '-ar', '44100', '-ac', '2', '-shortest', avi], check=True)
    p = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'stream=codec_name,codec_tag_string,width,height,has_b_frames:format=duration,size',
                        '-of', 'compact', avi], capture_output=True, text=True, check=True)
    print(p.stdout.strip())
    print('video used', video)
    print('wrote', avi)
    print('check', frames)
    print('server script movieSeconds must be at least the duration above')


if __name__ == '__main__':
    sys.exit(main())
