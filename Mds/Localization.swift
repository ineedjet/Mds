/**
 Finds a proper form of a given Russian noun for the specified item count.

 - Parameters:
   - count: The number of items.
   - forms: Three forms of a noun: for 1 item, for 2 items, and for 5 items.
     For example, `("книга", "книги", "книг")`.

 - Returns: A string that consists of the number `count`,
   followed by a space, and a noun in the proper form.
 */
func getRussianString(forNumber count: Int, andNounForms forms: (String,String,String)) -> String {
    let c = abs(count)
    if c%10 == 1 && c%100 != 11 {
        return "\(count) \(forms.0)"
    }
    if c%10 >= 2 && c%10 < 5 && (c%100)/10 != 1 {
        return "\(count) \(forms.1)"
    }
    return "\(count) \(forms.2)"
}
