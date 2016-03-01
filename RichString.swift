//
// RichString.swift
// 
// The MIT License (MIT)
// 
// Copyright (c) 2015-2016 Andy Teijelo <github.com/ateijelo>
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

extension UIColor {
    convenience init(htmlColor: String) {
        if let c = RichString.htmlColor(htmlColor) {
            self.init(CGColor: c.CGColor)
            return
        }
        self.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
}

struct StyleSpec {
    var fontName: String?
    var fontSize: CGFloat?
    var color: UIColor?
    var alignment: NSTextAlignment?
    var line_height: CGFloat?
    var baseline_offset: CGFloat?
}

class StringParser: NSObject, NSXMLParserDelegate {
    var attributedString = NSMutableAttributedString()
    var currentText = ""
    var styleStack = [
        StyleSpec(
            fontName: RichString.defaultFont.fontName,
            fontSize: UIFont.systemFontSize(),
            color: nil,
            alignment: nil,
            line_height: nil,
            baseline_offset: nil
        )
    ]
    var parser: NSXMLParser
    let R: RichString

    init(document: String, richString: RichString) {
        R = richString
        parser = NSXMLParser(data: document.dataUsingEncoding(NSUTF8StringEncoding)!)
        super.init()
        parser.delegate = self
    }
    
    func parse() {
        parser.parse()
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        closeRange()
        var f = styleStack.last!
        if let spec = R.styleMap[elementName] {
            f.fontName = spec.fontName ?? styleStack.last?.fontName
            f.fontSize = spec.fontSize ?? styleStack.last?.fontSize
            f.color = spec.color ?? styleStack.last?.color
            f.alignment = spec.alignment ?? styleStack.last?.alignment
            f.line_height = spec.line_height ?? styleStack.last?.line_height
            f.baseline_offset = spec.baseline_offset ?? styleStack.last?.baseline_offset
        }
        styleStack.append(f)
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        currentText += string
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        closeRange()
        styleStack.removeLast()
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        print("parsing error: \(parseError)")
    }
    
    func closeRange() {
        if currentText.isEmpty {
            //println("   text is empty, not doing anything")
            return
        }
        var currentAttributes: [String: AnyObject] = [:]
        
        //currentAttributes[NSKernAttributeName] = nil
        
        //        println("styleStack:")
        //        for spec in styleStack {
        //            println("  name: \(spec.fontName) size: \(spec.fontSize)")
        //        }
        
        let n = styleStack.last!.fontName!
        let s = styleStack.last!.fontSize!
        currentAttributes[NSFontAttributeName] = UIFont(name: n, size: s)
        if let c = styleStack.last?.color {
            currentAttributes[NSForegroundColorAttributeName] = c
        }
        
        var ps: NSMutableParagraphStyle? = nil
        
        if let a = styleStack.last?.alignment {
            if ps == nil {
                ps = NSMutableParagraphStyle()
            }
            ps!.alignment = a
        }
        if let lh = styleStack.last?.line_height {
            if ps == nil {
                ps = NSMutableParagraphStyle()
            }
            ps!.lineHeightMultiple = lh
        }
        if ps != nil {
            currentAttributes[NSParagraphStyleAttributeName] = ps!
        }
        
        if let bo = styleStack.last?.baseline_offset {
            currentAttributes[NSBaselineOffsetAttributeName] = bo
        }
        
        //        println("appending text \"\(currentText)\" with attributes \(currentAttributes)")
        
        attributedString.appendAttributedString(
            NSAttributedString(string: currentText, attributes: currentAttributes)
        )
        currentText = ""
    }
}


class RichString {

    static let defaultFont = UIFont.systemFontOfSize(UIFont.systemFontSize())

    var styleMap: [String: StyleSpec] = [:]
    static let ruleRegex = try? NSRegularExpression(pattern: "\\s*([\\w-]+)\\s*\\{(.*?)\\}", options: [])
    static let clauseRegex = try? NSRegularExpression(pattern: "\\s*([\\w-]+):\\s+(.*?);", options: [])

    let fmt = NSNumberFormatter()

    init(_ styles: String...) {
        parseStyles(styles.joinWithSeparator(""))
    }

    subscript (string: String) -> NSAttributedString {
        let doc = "<body>" + string + "</body>"

        let parser = StringParser(document: doc, richString: self)
        parser.parse()
        return parser.attributedString
        
    }
    
    static let hexDigits = {() -> [CChar:Int] in
        let digits = "0123456789abcdef".cStringUsingEncoding(NSASCIIStringEncoding)!
        var digitValue: [CChar:Int] = [:]
        for t in digits.enumerate() {
            digitValue[t.1] = t.0
        }
        return digitValue
    }()

    class func htmlColor(color: String) -> UIColor? {
        if !color.hasPrefix("#") {
            return nil
        }
        let l = color.characters.count
        if l != 7 && l != 9 {
            return nil
        }
        guard let chars = color.lowercaseString.cStringUsingEncoding(NSASCIIStringEncoding) else {
            return nil
        }
        for i in 1..<l {
            if hexDigits[chars[i]] == nil {
                return nil
            }
        }
        let r = hexDigits[chars[1]]! * 16 + hexDigits[chars[2]]!
        let g = hexDigits[chars[3]]! * 16 + hexDigits[chars[4]]!
        let b = hexDigits[chars[5]]! * 16 + hexDigits[chars[6]]!
        var a = 255
        if l == 9 {
            a = hexDigits[chars[7]]! * 16 + hexDigits[chars[8]]!
        }
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(a) / 255.0)
    }
    
    class func parseColor(color: String) -> UIColor? {
        let fmt = NSNumberFormatter()
        if color.hasPrefix("rgb") {
            guard let regex = try? NSRegularExpression(pattern: "rgba?\\s*\\((\\d+)\\s*,\\s*(\\d+)\\s*,\\s*(\\d+)(\\s*,\\s*(\\d+)\\s*)?\\)", options: [])
                else { return nil }
            let matches = regex.matchesInString(color, options: [], range: NSMakeRange(0, color.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)))
            if matches.count == 0 {
                print("did not understand rgb color value: \(color)")
                return nil
            }
            var a: [CGFloat] = [0, 0, 0, 0, 255] // the fourth value is unused, color is formed from a[0], a[1], a[2], a[4]
            for i in [1,2,3,5] {
                let range = matches[0].rangeAtIndex(i)
                if range.length == 0 { continue }
                guard let val = fmt.numberFromString(NSString(string: color).substringWithRange(range)) else {
                    print("Error parsing number in \(color)")
                    return nil
                }
                a[i-1] = CGFloat(val)
            }
            
            return UIColor(red: a[0] / 255.0, green: a[1] / 255.0, blue: a[2] / 255.0, alpha: a[4] / 255.0)
        } else if color.hasPrefix("#") {
            return RichString.htmlColor(color)
        }
        print("did not understand color value: \(color)")
        return nil
    }

    func parseClauses(clauses: NSString) -> StyleSpec {
        var spec = StyleSpec()
        if let regex = RichString.clauseRegex {
            let matches = regex.matchesInString(clauses as String, options: [], range: NSMakeRange(0, clauses.length))
            for m in matches {
                let k = clauses.substringWithRange(m.rangeAtIndex(1))
                let v = clauses.substringWithRange(m.rangeAtIndex(2))
                switch k {
                case "font-name":
                    spec.fontName = v
                case "font-size":
                    if let s = fmt.numberFromString(v)?.floatValue {
                        spec.fontSize = CGFloat(s)
                    }
                case "color":
                    spec.color = RichString.parseColor(v)
                case "align", "text-alignment", "alignment":
                    switch v {
                    case "left":
                        spec.alignment = .Left
                    case "center":
                        spec.alignment = .Center
                    case "right":
                        spec.alignment = .Right
                    case "justified":
                        spec.alignment = .Justified
                    case "natural":
                        spec.alignment = .Natural
                    default:
                        break
                    }
                case "line-height":
                    if let n = fmt.numberFromString(v)?.floatValue {
                        spec.line_height = CGFloat(n)
                    }
                case "baseline-offset":
                    if let n = fmt.numberFromString(v)?.floatValue {
                        spec.baseline_offset = CGFloat(n)
                    }
                default:
                    break
                }
            }
        }
        return spec
    }

    func parseStyles(styles: String) {
        if let regex = RichString.ruleRegex {
            let matches = regex.matchesInString(styles, options: [], range: NSMakeRange(0,styles.characters.count))
            let nsstyles = styles as NSString
            for m in matches {
                styleMap[nsstyles.substringWithRange(m.rangeAtIndex(1))] =
                    parseClauses(nsstyles.substringWithRange(m.rangeAtIndex(2)))
            }
        }
    }
}
