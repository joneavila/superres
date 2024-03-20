import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()

    var body: some View {
        HStack(spacing: 0) {
            // Controls
            VStack(alignment: .leading) {
                Button("Select Image") {
                    viewModel.selectImage()
                }
                .buttonStyle(CustomButtonStyle(useMaxWidth: true))

                Text("Settings")
                    .headingTextStyle()
                    .padding(.top, 20)

                Toggle("Automatically save upscaled images", isOn: $viewModel.automaticallySave)
                    .textStyle()
                    .padding(.bottom, 7)
                    .toggleStyle(CustomToggleStyle())

                if viewModel.automaticallySave {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Output Folder")
                            .subheadingTextStyle()

                        HStack {
                            Text(viewModel.outputFolderDisplayPath)
                                .valueTextStyle()
                            Button {
                                viewModel.selectOutputFolder()
                            } label: {
                                Image(systemName: "folder.fill")
                            }
                            .buttonStyle(CustomButtonStyle())
                        }
                    }
                }

                Spacer()

                Button("Upscale") {
                    viewModel.upscaleImage()
                }

                .buttonStyle(CustomButtonStyle(isProminent: true, useMaxWidth: true))
                .disabled(viewModel.originalImage == nil)
            }
            .padding()
            .frame(width: 200, alignment: .leading)
            .background(Color("BgColor"))
            .disabled(viewModel.isUpscaling)

            // Divider
            Rectangle()
                .fill(Color("BgDividerColor"))
                .frame(width: 1)
                .ignoresSafeArea()

            // Image view
            ZStack {
                Color("BgDimColor")
                if let originalImage = viewModel.originalImage, let upscaledImage = viewModel.upscaledImage {
                    ImageCompareView(
                        beforeImage: originalImage,
                        afterImage: upscaledImage
                    )
                    .padding(.horizontal, 28)
                } else if let originalImage = viewModel.originalImage {
                    ImageView(image: originalImage)
                        .padding(.horizontal, 28)
                } else {
                    ImagePlaceholderView()
                        .padding()
                }
                if viewModel.isUpscaling {
                    SpinnerView()
                }

                // Save button
                if viewModel.upscaledImage != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                viewModel.saveUpscaledImageToLocation()
                            } label: {
                                Image(systemName: "arrow.down.to.line")
                                    .bold()
                            }
                            .buttonStyle(CustomButtonStyle())
                        }
                    }
                    .padding(.horizontal, 14)
                }

                // Image saved message
                VStack {
                    Spacer()
                    Text("Image saved")
                        .textStyle()
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color("BgColor"))
                                .stroke(Color("BgDividerColor"), lineWidth: 1)
                        )
                        .padding(.bottom, 8)
                }
                .opacity(viewModel.showSuccessMessage ? 1 : 0)
                .animation(.easeInOut, value: viewModel.showSuccessMessage)
            }
            .padding(.vertical, 16)
            .background(Color("BgDimColor"))
            .ignoresSafeArea()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDropOfImage(providers: providers)
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.alertIsPresented) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

struct ImagePlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Select an image, or drag and drop an image here")
                .subtextStyle()
            Image(systemName: "cursorarrow.and.square.on.square.dashed")
                .resizable()
                .scaledToFit()
                .frame(width: 38)
                .foregroundColor(Color("FgSecondaryColor"))
        }
    }
}

struct ImageView: View {
    let image: NSImage

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .cornerRadius(6)
    }
}

struct SpinnerView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .frame(width: 50, height: 50)
            ProgressView()
        }
    }
}

#Preview("ContentView") {
    ContentView()
}

#Preview("ImagePlaceholderView") {
    ImagePlaceholderView()
}

#Preview("ImageView") {
    ImageView(image: NSImage(named: "ComicImage")!)
}

#Preview("SpinnerView") {
    SpinnerView()
}
