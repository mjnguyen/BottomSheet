//
//  BottomSheetButton.swift
//  SHSwiftModern
//
//  Created by Nguyen, Michael on 2/19/25.
//
import SwiftUI
import UIKit

/// Defines button roles for styling and behavior
@objc
public enum BottomSheetButtonRole: Int {
    case primary
    case destructive
    case cancel
    case `default`
}

/// Defines a button inside the BottomSheetAdapter
@objc
public class BottomSheetButton: NSObject {
    let title: String
    let role: BottomSheetButtonRole
    let action: () -> Void

    public init(title: String, role: BottomSheetButtonRole = .default, action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }
}

/// Button View that applies styling based on role
public struct BottomSheetButtonView: View {
    let button: BottomSheetButton

    public var body: some View {
        Button(action: button.action) {
            Text(button.title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(0)
                .border(Color("shc.cellBorderColor", bundle: .main), width: 1.0)
        }
    }

    private var backgroundColor: Color {
        switch button.role {
        case .primary: return Color("shc.brightBlue", bundle: .main)
        case .destructive: return Color("shc.primaryRed", bundle: .main)
        case .cancel: return Color("shc.primaryGrey", bundle: .main)
        case .default: return  Color("shc.brightBlue", bundle: .main)
        }
    }

    private var foregroundColor: Color {
        button.role == .default ?  Color("shc.primaryWhite", bundle: .main) :  Color("shc.primaryBlack", bundle: .main)
    }
}
