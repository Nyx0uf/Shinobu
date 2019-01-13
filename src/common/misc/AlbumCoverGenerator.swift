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
