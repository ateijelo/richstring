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
    "title { font-face: Helvetica; font-size: 15; }",
    "subtitle { font-face: Helvetica; font-size: 13.5; }",
    "b { font-face: Helvetica-Bold; }",
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


### Reference

As of March 2016, RichString understand the following attributes:

#### font-face

Selects the font face for the given rule. You must use the font's PostScript name. That's the name that has a hyphen in the middle. Check FontBook. Example:

```CSS
  title { font-face: Helvetica-Bold; }
```

#### font-size

This is the size in points. It's a floating point value, with no units. Example:

```CSS
  title { font-size: 10.5; }
```

####
