///
///  BottomSheetView.swift
///  SHSwiftModern
///
///  Created by Nguyen, Michael on 2/17/25.
///

import SwiftUI
import UIKit

struct BottomSheetView<Content: View>: View {
    let title: String
    let category: BottomSheetCategory?
    let buttons: [BottomSheetButton]
    let dismissAction: (() -> Void)?
    let content: Content
    
    @Binding var detents: Set<PresentationDetent> // Binding to receive detents
    @Binding var totalHeight: CGFloat // Binding for total height
    var onUpdateDetents: ((Set<PresentationDetent>) -> Void)? // Closure for detent updates

    @State private var isExpanded: Bool = false
    @State private var contentHeight: CGFloat = 0
    @State private var titleHeight: CGFloat = 0
    @State private var buttonHeight: CGFloat = 0

    @State private var sheetID: UUID = UUID()

    var body: some View {

        GeometryReader { geometry in
            Spacer()
            VStack(spacing: 0) {
                // Title and Image Section
                VStack {
                    if let category = category, let uiImage = category.getUIImage() {
                        let foregroundColor = category == .error ? Color.red : Color.gray
                        Image(uiImage: uiImage)
                            .renderingMode(.template)
                            .foregroundColor(foregroundColor)
                            .padding(.top, 30)
                    }

                    Text(title)
                        .font(.headline)
                        .padding(.top, 10)
                }
                .background(GeometryReader { titleGeometry in
                    Color.clear
                        .onAppear {
                            titleHeight = titleGeometry.size.height
                            print("title height: \(titleHeight)")
                            updateTotalHeight()
                        }
                })
                Divider()
                GeometryReader { proxy in
                    Spacer()
                    ViewThatFits {
                        // Scrollable content
                        VStack {
                            Spacer()

                            content
                                .fixedSize(horizontal: false, vertical: true) // Allow content to shrink
                                .background(GeometryReader { innerGeometry in
                                    Color.clear
                                        .onAppear {
                                            contentHeight = innerGeometry.size.height
                                            updateTotalHeight()
                                        }
                                        .onChange(of: innerGeometry.size.height) { newHeight in
                                            contentHeight = newHeight
                                            print("1 content height changed to \(newHeight)")
                                            updateTotalHeight()
                                        }
                                })
                        }

                        ScrollView {
                            Spacer()

                            VStack(alignment: .leading, spacing: 0) {
                                content
                            }
                            .background(GeometryReader { innerGeometry in
                                Color.clear
                                    .onAppear {
                                        contentHeight = innerGeometry.size.height
                                        updateTotalHeight()
                                    }
                                    .onChange(of: innerGeometry.size.height) { newHeight in
                                        contentHeight = newHeight
                                        print("content height changed to \(newHeight)")
                                        updateTotalHeight()
                                    }
                            })
                            .fixedSize(horizontal: false, vertical: true) // Allow content to shrink
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 10)


                    }
                    .fixedSize(horizontal: false, vertical: true) // Allow content to shrink
                    .clipped()
                    .border(Color.gray, width: 0.5)
                }

                // Fixed button section
                if !buttons.isEmpty {
                    Spacer()
                    Divider()
                    VStack(spacing: 10) {
                        ForEach(buttons.indices, id: \.self) { index in
                            BottomSheetButtonView(button: buttons[index])
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .background(GeometryReader { buttonGeometry in
                        Color.clear
                            .onAppear {
                                buttonHeight = buttonGeometry.size.height
                                updateTotalHeight()
                                print("detents updated: \(detents)")
                            }
                            .onChange(of: buttonGeometry.size.height) { newHeight in
                                buttonHeight = newHeight
                                print("Button height updated to \(newHeight)")
                                updateTotalHeight()
                            }
                    })
                }
            }
        }
        .id(sheetID)
        .presentationDetents(detents)
    }

    private func updateTotalHeight() {
        totalHeight = contentHeight + titleHeight + buttonHeight
        // Call the onUpdateDetents closure to notify the adapter
        var updatedDetentsSet: Set<PresentationDetent> = []
        // Determine additional detents based on total height

        if totalHeight < UIScreen.main.bounds.height * 0.30 {
            updatedDetentsSet.insert(.fraction(0.30)) // Smallest fraction for compact UI
        } else if totalHeight < UIScreen.main.bounds.height * 0.6 {
            updatedDetentsSet.insert(.medium) // Use medium when reasonable
        } else if totalHeight < UIScreen.main.bounds.height * 0.8 {
            updatedDetentsSet.insert(.height(totalHeight)) // Use medium when reasonable
        } else {
            updatedDetentsSet.insert(.large) // Default to large for taller views
        }

        print("current detents: \(detents)")
        if (!detents.elementsEqual(updatedDetentsSet)) {
            print("totalHeight: \(totalHeight) : detents: \(updatedDetentsSet)")

            onUpdateDetents?(updatedDetentsSet)
            detents = updatedDetentsSet
            sheetID = UUID()
            isExpanded.toggle()
            print ("new sheet id: \(sheetID)")
        }

    }
}

// Preview
@available(iOS 16.0, *)
#Preview {

    struct ContentView: View {
        @State private var showInfoSheet = false
        @State private var detents: Set<PresentationDetent> = [.fraction(0.30)] // 🔥 Control detents from here

        var body: some View {
            VStack {
                Button("Show Info Sheet") {
                    showInfoSheet.toggle()
                }
            }

            .sheet(isPresented: $showInfoSheet) {
                let sheet = BottomSheetAdapter(
                    title: "Warning",
                    category: .error,
                    detents: $detents,
                    prefersGrabberVisible: true,
                    isInteractiveDismissEnabled: true,
                    cornerRadius: 30,
                    buttons: [
                        BottomSheetButton(title: "Confirm".uppercased(), role: .primary, action: { print("Confirmed") }),
                        BottomSheetButton(title: "TRY THIS", role: .default, action: { print("Cancelled") }),
//                        BottomSheetButton(title: "Cancel", role: .cancel, action: { print("Cancelled") }),
//                        BottomSheetButton(title: "Delete", role: .destructive, action: { print("Cancelled") })
                    ]
                ) {
                    Text("Are you sure you want to proceed? Longer mesage lkasdjflk asdlf jsaldf lsadfj lsa flsd jfls dflksd flk")
                    Text("** Are you sure you want to proceed? Longer mesage lkasdjflk asdlf jsaldf lsadfj lsa flsd jfls dflksd flk")
//                    Text("*** Are you sure you want to proceed? Longer mesage lkasdjflk asdlf jsaldf lsadfj lsa flsd jfls dflksd flk")
                    Text("**** Are you sure you want to proceed? Longer mesage lkasdjflk asdlf jsaldf lsadfj lsa flsd jfls dflksd flk")
                    Text("Are you sure you want to proceed?")
//                    Text("Additional message line.")
                    Text("Another message.")
//                    Text("Are you sure you want to proceed? Longer mesage lkasdjflk asdlf jsaldf lsadfj lsa flsd jfls dflksd flk")
                    Text("LastMessage .")
                }
                .presentationDragIndicator(.visible)

                sheet
//                    .presentationDetents(detents) // uncommenting this affects the detents actually used.
            }
        }

    }

    return ContentView()
}
