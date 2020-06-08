//
//  TapThemeManagerParser.swift
//  TapThemeManager2020
//
//  Created by Osama Rabie on 08/03/2020.
//  Copyright © 2020 Osama Rabie. All rights reserved.
//
import class UIKit.UIImage
import class UIKit.UIFont
import class UIKit.UIColor
import struct UIKit.CGFloat
import enum UIKit.UIStatusBarStyle
import enum TapFontsKit.TapFont
import class LocalisationManagerKit_iOS.TapLocalisationManager

/// All the methods required to parse String values provided in the theme file into readable iOS values like UIColor, UIFont, etc.
@objc extension TapThemeManager {
    
    /**
    - The method for getting a certain value in the current theme dictrionary
    - Parameter keyPath: The key of the value needed
    - Returns: The value of the key, could be another object, String, Number, etc.
    */
    public class func value(for keyPath: String) -> Any? {
        return currentTheme?.value(forKeyPath: keyPath)
    }
    
    /**
    - The method for getting a STRING value from the current theme dictionary
    - Parameter keyPath: The key of the string needed
    - Returns: The STRING value of the key, and nil if doesn't exist
    */
    public class func stringValue(for keyPath: String) -> String? {
        guard let parsedString = currentTheme?.value(forKeyPath: keyPath) as? String else {
            print("TapThemeManager WARNING: Not found string key path: \(keyPath)")
            return nil
        }
        return parsedString
    }
    
    /**
    - The method for getting a Numeric value from the current theme dictionary
    - Parameter keyPath: The key of the Number needed
    - Returns: The NSNumber value of the key, and nil if doesn't exist
    */
    public class func numberValue(for keyPath: String) -> NSNumber? {
        guard let parsedNumber = currentTheme?.value(forKeyPath: keyPath) as? NSNumber else {
            print("TapThemeManager WARNING: Not found number key path: \(keyPath)")
            return nil
        }
        return parsedNumber
    }
    
    /**
    - The method for getting a dictionary value from the current theme dictionary
    - Parameter keyPath: The key of the dictionary needed
    - Returns: The dictionary value of the key, and nil if doesn't exist
    */
    public class func dictionaryValue(for keyPath: String) -> NSDictionary? {
        guard let parsedDictionary = currentTheme?.value(forKeyPath: keyPath) as? NSDictionary else {
            print("TapThemeManager WARNING: Not found dictionary key path: \(keyPath)")
            return nil
        }
        return parsedDictionary
    }
    
    
    /**
    - The method for getting a UIColor value from the current theme dictionary
    - Parameter keyPath: The key of the UIColor needed
    - Returns: The UIColor value of the key, and nil if doesn't exist
    */
    public class func colorValue(for keyPath: String) -> UIColor? {
        // First we need to gett tthe HEX value as string
        guard let parsedRGBString = stringValue(for: keyPath) else { return nil }
        // We need to check did the theme pass a hex color or a name of a saved color
        guard let parsedColor = try? UIColor(tap_hex: parsedRGBString) else {
            // This means, the user didn't pass a valid HEX value, could be the a name of a registered color in theme file in the path Global.Colors
            print("TapThemeManager WARNING: Not convert RGBA Hex string \(parsedRGBString) at key path: \(keyPath). Will check if there is a valid color provided in the path GlobalValues.Colors.\(parsedRGBString)")
            return globalColorValue(for: "GlobalValues.Colors.\(parsedRGBString)")
        }
        return parsedColor
    }
    
    /**
     - The method for getting a UIColor value from the current theme dictionary from the global colors section
     - Parameter keyPath: The key of the UIColor needed
     - Returns: The UIColor value of the key, and nil if doesn't exist
     */
    private class func globalColorValue(for keyPath: String) -> UIColor? {
        // First we need to gett tthe HEX value as string
        guard let parsedRGBString = stringValue(for: keyPath) else { return nil }
        // let us check if the user provided a valid hex color
        guard let parsedColor = try? UIColor(tap_hex: parsedRGBString) else {
            print("TapThemeManager WARNING: Not convert RGBA Hex string \(parsedRGBString) at key path: \(keyPath)")
            return nil
        }
        return parsedColor
    }
    
    
    /**
    - The method for getting a UIStatusBarStyle value from the current theme dictionary
    - Parameter keyPath: The key of the UIStatusBarStyle needed
    - Returns: The UIStatusBarStyle value of the key, and .default if doesn't exist
    */
    public class func themeStatusBarStyle(for keyPath: String) -> UIStatusBarStyle {
        // First we need to get the statusStyle value as string
        guard let parsedStatusString = stringValue(for: keyPath) else { return .default }
        switch parsedStatusString.lowercased() {
            case "default"      : return .default
            case "lightcontent" : return .lightContent
            case "darkcontent"  : if #available(iOS 13.0, *) { return .darkContent } else { return .default }
            default: return .default
        }
    }
    
    /**
       - The method for getting a UIImage value from the current theme dictionary
       - Parameter keyPath: The key of the UIImage needed
       - Returns: The UIImage value of the key, and nil if doesn't exist
       */
    public class func imageValue(for keyPath: String) -> UIImage? {
        guard let parsedImageName = stringValue(for: keyPath) else { return nil }
        // Incase we will add afterwards reading from different paths other than the Main Bundle
        if let filePath = TapThemePath.themeURL?.appendingPathComponent(parsedImageName).path {
           return imageValue(fromLocalURL: filePath)
        } else {
            // Try to parse the image from the main bundle
            return imageValue(imageName: parsedImageName)
        }
    }
    
    /**
    - The method for getting a UIFont value from the current theme dictionary. The fonts can be provided whether NAME,SIZE or SIZE or NAME
    - Parameter keyPath: The key of the UIFont needed
    - Returns: The UIFont value of the key, and nil if doesn't exist
    */
    public class func fontValue(for keyPath: String) -> UIFont? {
        // First of all, check if the font textual info presented
        guard let parsedFontString = stringValue(for: keyPath) else { return nil }
        return fontValue(from: parsedFontString)
    }
    
    internal class func fontValue(from string: String) -> UIFont {
        // Check if the theme file provides both font name and font size
        let elements = string.components(separatedBy: ",")
        if elements.count == 2 {
            // Check first if the font exists in the caller main bundle
            if let fontFromMainBundle = UIFont(name: elements[0], size: CGFloat(Float(elements[1])!)) {
                return fontFromMainBundle
            }else{
                // If not, we check it in our default common fonts kit
                do {
                  let data = try JSONEncoder().encode(elements[0])
                  let decoder = JSONDecoder()
                  let tapFont:TapFont = try decoder.decode(TapFont.self, from: data)
                    return tapFont.localizedWithSize(CGFloat(Float(elements[1])!), languageIdentifier: (TapLocalisationManager.shared.localisationLocale ?? "en"))
                } catch {
                  print(error.localizedDescription)
                }
            }
        }
        
        // Check if the theme file provides ONLY size, then we just provide the system font with tthe given size
        if let fontSize = Float(string), fontSize > 0 {
            return UIFont.systemFont(ofSize: CGFloat(fontSize))
        }
        
        // Not to break, we return default font and size
        let value = "UICTFontTextStyle" + string.capitalized
        return UIFont.preferredFont(forTextStyle: UIFont.TextStyle(rawValue: value))
    }
    
    /**
    - The method for getting a UIImage value from a given URL
    - Parameter fromLocalURL: The path of the UIImage needed
    - Returns: The UIImage value of the key, and nil if doesn't exist
    */
    internal class func imageValue(fromLocalURL:String) -> UIImage? {
        guard let parsedImage = UIImage(contentsOfFile: fromLocalURL) else {
            print("TapThemeManager WARNING: Not found image at file path: \(fromLocalURL)")
            return nil
        }
        return parsedImage
    }
    
    
    /**
    - The method for getting a UIImage value from the main bundle
    - Parameter imageName: The needed image name
    - Returns: The UIImage value of the key, and nil if doesn't exist
    */
    internal class func imageValue(imageName:String) -> UIImage? {
        guard let parsedImage = UIImage(named: imageName) else {
            print("TapThemeManager WARNING: Not found image name at main bundle: \(imageName)")
            return nil
        }
        return parsedImage
    }
}
