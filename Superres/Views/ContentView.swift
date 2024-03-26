import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    @State private var selectedImageState: ImageState?

    var body: some View {
        HStack(spacing: 0) {
            // Controls
            VStack(alignment: .leading) {
                Button("Select Images") {
                    viewModel.selectImages()
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
                    Task {
                        await viewModel.upscaleImages()
                    }
                }

                .buttonStyle(CustomButtonStyle(isProminent: true, useMaxWidth: true))
                .disabled(!viewModel.imagesNeedUpscaling)
            }
            .padding()
            .frame(width: 200, alignment: .leading)
            .background(Color("BgColor"))
            .disabled(viewModel.isUpscaling)

            DividerView()

            // Image view
            ZStack {
                Color("BgDimColor")
                if viewModel.imageStates.isEmpty {
                    ImagePlaceholderView()
                        .padding()

                } else {
                    GeometryReader { geometry in
                        ScrollView {
                            let width = geometry.size.width
                            let imageWidth = 200.0
                            let imageHeight = 150.0
                            let numberOfColumns = Int(width / imageWidth)
                            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: max(numberOfColumns, 1))
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(viewModel.imageStates.indices, id: \.self) {
                                    index in
                                    ImageView(imageState: viewModel.imageStates[index])
                                        .frame(height: imageHeight)
                                        .padding(.horizontal, 10)
                                        .onTapGesture {
                                            selectedImageState = viewModel.imageStates[index]
                                        }
                                }
                            }
                        }
                        .padding(18)
                    }
                }

                // Image saved message
                VStack {
                    Spacer()
                    Text("Images automatically saved")
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

            if let selectedImage = selectedImageState, let upscaledImage = selectedImage.upscaledImage {
                DividerView()
                ZStack {
                    Color("BgColor")
                        .ignoresSafeArea()
                    VStack {
                        ImageCompareView(beforeImage: selectedImage.originalImage, afterImage: upscaledImage)
                            .padding(.horizontal, 20)
                        Button("Save Image") {
                            viewModel.saveUpscaledImageToLocation(imageState: selectedImage)
                        }
                        .buttonStyle(CustomButtonStyle())
                    }
                    .padding()
                }
            }
        }

        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDropOfImages(providers: providers)
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

struct DividerView: View {
    var body: some View {
        Rectangle()
            .fill(Color("BgDividerColor"))
            .frame(width: 1)
            .ignoresSafeArea()
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

#Preview("SpinnerView") {
    SpinnerView()
}
