import UIKit


final class TopAlignedLabel : UILabel
{
	override func drawText(in rect: CGRect)
	{
		// If one line, we can just use the lineHeight, faster than querying sizeThatFits
		let height = (numberOfLines == 1) ? ceil(font.lineHeight) : ceil(sizeThatFits(size).height)

		var r = rect
		if height < height
		{
			r.y = ((height - height) / 2.0) * -1.0
		}

		super.drawText(in: r)
	}
}
