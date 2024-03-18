import SwiftUI

struct Resource {
    let id = UUID()
    let name: String
    let url: URL
    let description: String
    let author: String
    let license: String?
    let licenseUrl: URL?
}

struct AcknowledgementsView: View {
    @State private var resources: [Resource] = [
        Resource(
            name: "CoreML-Models",
            url: URL(string: "https://github.com/john-rocky/CoreML-Models")!,
            description: "Real-ESRGAN Core ML model",
            author: "MLBoy_DaisukeMajima",
            license: nil,
            licenseUrl: nil
        ),
        Resource(
            name: "CoreMLHelpers",
            url: URL(string: "https://github.com/hollance/CoreMLHelpers")!,
            description: "Conversion between CGImage and CVPixelBuffer",
            author: "Matthijs Hollemans",
            license: "MIT License",
            licenseUrl: URL(string: "https://github.com/hollance/CoreMLHelpers?tab=MIT-1-ov-file")!
        ),
        Resource(
            name: "Minimal",
            url: URL(string: "https://github.com/kepano/obsidian-minimal")!,
            description: "Color scheme",
            author: "Stephan Ango",
            license: "MIT License",
            licenseUrl: URL(string: "https://github.com/kepano/obsidian-minimal?tab=MIT-1-ov-file")!
        ),
        Resource(
            name: "Readex Pro",
            url: URL(string: "https://fonts.google.com/specimen/Readex+Pro")!,
            description: "Font",
            author: "Thomas Jockin, Nadine Chahine, Bonnie Shaver-Troup, Santiago Orozco, Héctor Gómez",
            license: "OFL-1.1 License",
            licenseUrl: URL(string: "https://openfontlicense.org/documents/OFL.txt")!
        ),
        Resource(
            name: "Polkadot Butterfly",
            url: URL(string: "https://commons.wikimedia.org/wiki/File:Polkadot_butterfly_(14136135962).jpg")!,
            description: "Preview Assets image",
            author: "Rene Mensen",
            license: "CC BY 2.0 DEED Attribution 2.0 Generic License",
            licenseUrl: URL(string: "https://creativecommons.org/licenses/by/2.0/deed.en")!
        ),
    ]

    var body: some View {
        ZStack {
            Color("BgColor")
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach($resources, id: \.id) { $resource in
                        VStack(alignment: .leading, spacing: 4) {
                            Link(resource.name, destination: resource.url)
                                .foregroundStyle(Color("FgLinkColor"))
                                .headingTextStyle()

                            Text(resource.description)
                                .subtextStyle()

                            Text(resource.author)
                                .textStyle()

                            if let license = resource.license, let licenseUrl = resource.licenseUrl {
                                Link(license, destination: licenseUrl)
                                    .foregroundStyle(Color("FgLinkColor"))
                                    .textStyle()
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color("BgColor"))
        }
        .frame(width: 375)
    }
}

#Preview {
    AcknowledgementsView()
}
