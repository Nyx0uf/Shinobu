// AlbumCoverGenerator.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit


func generateCoverForAlbum(_ album: Album, size: CGSize) -> UIImage?
{
	return generateCoverFromString(album.name, size: size, useGradient: false)
}

func generateCoverForGenre(_ genre: Genre, size: CGSize) -> UIImage?
{
	return generateCoverFromString(genre.name, size: size, useGradient: false)
}

func generateCoverForArtist(_ artist: Artist, size: CGSize) -> UIImage?
{
	return generateCoverFromString(artist.name, size: size, useGradient: false)
}

func generateCoverForPlaylist(_ playlist: Playlist, size: CGSize) -> UIImage?
{
	return generateCoverFromString(playlist.name, size: size, useGradient: false)
}

func generateCoverFromString(_ string: String, size: CGSize, useGradient: Bool = false) -> UIImage?
{
	let backgroundColor = UIColor(rgb: string.djb2())
	if useGradient
	{
		if let gradient = makeLinearGradient(startColor: backgroundColor, endColor: backgroundColor.inverted())
		{
			return UIImage.fromString(string, font: UIFont(name: "Chalkduster", size: size.width / 4.0)!, fontColor: backgroundColor.inverted(), gradient: gradient, maxSize: size)
		}
	}
	return UIImage.fromString(string, font: UIFont(name: "Chalkduster", size: size.width / 4.0)!, fontColor: backgroundColor.inverted(), backgroundColor: backgroundColor, maxSize: size)
}

private func makeLinearGradient(startColor: UIColor, endColor: UIColor) -> CGGradient?
{
	let colors = [startColor.cgColor, endColor.cgColor]

	let colorSpace = CGColorSpace.NYXAppropriateColorSpace()

	let colorLocations: [CGFloat] = [0.0, 1.0]

	let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)
	return gradient
}
