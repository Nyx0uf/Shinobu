import CoreImage


final class CoreImageUtilities
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = CoreImageUtilities()
	// Software context
	private(set) lazy var swContext: CIContext = {
		let swContext = CIContext(options: [CIContextOption.useSoftwareRenderer : true])
		return swContext
	}()
	// Hardware context
	private(set) lazy var hwContext: CIContext = {
		let hwContext = CIContext(options: [CIContextOption.useSoftwareRenderer : false])
		return hwContext
	}()
	//
	private(set) lazy var isHeicCapable: Bool = {
		if #available(iOS 11.0, *)
		{
			let types = CGImageDestinationCopyTypeIdentifiers() as! [String]
			return types.contains("public.heic")
		}
		else
		{
			return false
		}
	}()
}
