# RichString
### NSAttributedString made pleasant

RichString is a CSS & HTML inspired way of working with the abominable & trauma-inducing interface of NSAttributedString & family in Apple's Core Foundation.

With RichString, you won't hesitate at the thought of font faces, sizes, colors, alignment and even line-height and baseline offsets.

RichString is inspired on CSS and HTML, but **RichString is NOT a CSS and HTML engine**, it just feels like one.

### Usage

To use RichString you will create an instance and pass it a set of CSS-looking rules. You can pass several rules as a single argument or, to make Swift's compiler happier, pass several arguments. It'll make no difference, RichString will parse them all as one:

```Swift
class MyMassiveViewController : UIViewController {

  let R = RichString(
    "title { font-name: Helvetica; font-size: 15; }",
    "subtitle { font-name: Helvetica; font-size: 13.5; }",
    "b { font-name: Helvetica-Bold; }",
  )

}
```

And then, whenever you need a NSAttributedString, you use subscripting on your `R` instance:

```Swift
...
  label.attributedText = R["<title>Hello <b>World!</b></title><subtitle>A message from RichString</subtitle>"]
...
```

### Caveats

RichString rules look lice CSS, and that's intentional. But RichString is not a CSS engine. Rules must have this format:

```CSS
  tag { attr: value; attr: value; }
```

There are no other kind of selectors, you can only use a simple tag name.

When subscripting, you write something that resembles HTML, but is actually XML parsed by Apple's NSXMLParser. So, whitespace counts. The following (note the `\n` character):

```Swift
label.attributedText = R["<title>Hello</title>\n<subtitle>World</subtitle>"]
```

will be rendered as two lines.

### Inheritance

RichString uses a limited form of CSS-inspired inheritance. Simply put: every attribute is inherited from the parent element. If you specify no styles, RichString will start with `UIFont.systemFontOfSize(UIFont.systemFontSize())`.

You can use the special tag `body` to give styles to all your strings, like this:

```Swift
let R = RichString("body { font-name: OpenSans; }")
...
label.attributeText = R["Hello, World!"]
```

### Attributes

As of March 2016, RichString understand the following attributes:

#### font-name

Selects the font face for the given rule. You must use the font's PostScript name. That's the name that has a hyphen in the middle. Check FontBook. Example:

```CSS
title { font-name: Helvetica-Bold; }
```

#### font-size

Sets the font size in points. It's a floating point value, with no units. Example:

```CSS
title { font-size: 10.5; }
```

#### color

Sets the text color. It must be in one of these two formats:

 * `#abcdef` with alpha set to 1.0
 * `#abcdef12` with alpha specified in the last two digits


 Example:

 ```CSS
title { color: #0000ff; }    /* opaque blue       */
title { color: #00ff0080; }  /* transparent green */
 ```

#### align, text-alignment, alignment

All three names do the same. I kept forgetting which one I had used so I put them all in.
This selects horizontal text alignment. Valid values are these:

```CSS
title { align: left; }       /* NSTextAlignment.Left       */
title { align: center; }     /* NSTextAlignment.Center     */
title { align: right; }      /* NSTextAlignment.Right      */
title { align: justified; }  /* NSTextAlignment.Justified  */
title { align: natural; }    /* NSTextAlignment.Natural    */
```

#### line-height

Sets the line height multiplier. It translates to a `NSParagraphStyle.lineHeightMultiple`. It is a unit-less floating point value. Example:

```CSS
title { line-height: 0.9; }
```

#### baseline-offset

Sets the text baseline offset. Positive is up, negative is down. It translates to `NSBaselineOffsetAttributeName`. It is a unit-less floating point value. Example:

```CSS
title { baseline-offset: -1.5; }
```
