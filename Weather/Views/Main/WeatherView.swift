//
//  HomeView.swift
//  Weatherly
//
//  Created by Екатерина Токарева on 02/12/2022.
//

import SwiftUI
import BottomSheet


enum BottomSheetPosition: CGFloat, CaseIterable {
    case top = 0.83
    case middle = 0.385
}

struct WeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    @State var bottomSheetPosition: BottomSheetPosition = .middle
    @State var bottomSheetTranslation: CGFloat = BottomSheetPosition.middle.rawValue
    @State var hasDragged: Bool = false
    
    var bottomSheetTranslationProrated: CGFloat {
        (bottomSheetTranslation - BottomSheetPosition.middle.rawValue) / (BottomSheetPosition.top.rawValue - BottomSheetPosition.middle.rawValue)
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let screenHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
                let imageOffset = screenHeight + 36
                ZStack {
                    // MARK: Background Color
                    Color.background
                        .ignoresSafeArea()
                    
                    // MARK: Background Image
                    Image("Background")
                        .resizable()
                        .ignoresSafeArea()
                    
                    // MARK: House Image
                    Image("House")
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, 257)
                        .offset(y: -bottomSheetTranslationProrated * imageOffset)
                    
                    //MARK: Current Weather
                    VStack(spacing: -10 * (1 - bottomSheetTranslationProrated)) {
                        Text(viewModel.cityName)
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        VStack {
                            Text(attributedString)
                                .multilineTextAlignment(.center)
                            
                            Text("H:\(viewModel.maxTemperature)°   L:\(viewModel.minTemperature)°")
                                .font(.title3.weight(.semibold))
                                .opacity(1 - bottomSheetTranslationProrated)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 51)
                    .offset(y: -bottomSheetTranslationProrated * 46)
                    //MARK: Botoom Sheet
                    BottomSheetView(position: $bottomSheetPosition) {
                        //Text(bottomSheetTranslationProrated.formatted())
                    } content: {
                        ForecastView(bottomSheetTranslationProrated: bottomSheetTranslationProrated)
                    }
                    .onBottomSheetDrag { translation in
                        bottomSheetTranslation = translation / screenHeight
                        
                        withAnimation(.easeInOut) {
                            if bottomSheetPosition == BottomSheetPosition.top {
                                hasDragged = true
                            } else {
                                hasDragged = false
                            }
                        }
                    }
                    
                    //MARK: Tab Bar
                    TabBar(action: {
                        bottomSheetPosition = .top
                    })
                    .offset(y: bottomSheetTranslationProrated * 115)
                }
                .navigationBarHidden(true)
                .alert(isPresented: $viewModel.shouldShowLocationError) {
                  Alert(
                    title: Text("Error"),
                    message: Text("To see the weather, provide location access in Settings."),
                    dismissButton: .default(Text("Open Settings")) {
                      guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                      UIApplication.shared.open(settingsURL)
                    }
                  )
                }
                .onAppear(perform: viewModel.refresh)
            }
        }
    }
    private var attributedString: AttributedString {
        var string = AttributedString("\(viewModel.temperature)°" + (hasDragged ? " | " : "\n") + "\(viewModel.weatherDescription)")
        if let temp = string.range(of: "\(viewModel.temperature)°") {
            string[temp].font = .system(size: (96 - (bottomSheetTranslationProrated * (96 - 20))), weight: hasDragged ? .semibold : .thin)
            string[temp].foregroundColor = hasDragged ? .white.opacity(0.5) : .white
           
        }
        
        if let pipe = string.range(of: " | ") {
            string[pipe].font = .title3.weight(.semibold)
            string[pipe].foregroundColor = .white.opacity(0.5).opacity(bottomSheetTranslationProrated)
        }
        
        if let weather = string.range(of: "\(viewModel.weatherDescription)") {
            string[weather].font = .title3.weight(.semibold)
            string[weather].foregroundColor = .white.opacity(0.5)
        }
        
        return string
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView(viewModel: WeatherViewModel(weatherService: WeatherService()))
            .preferredColorScheme(.dark)
    }
}
