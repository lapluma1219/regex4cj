/* Names corresponding to regex-capi. The Cangjie package is a static
   library, so the running entry is the Rure type and the rure CLI mode.
   rure_compile_must  -> Rure(pattern)
   rure_is_match      -> Rure.isMatch
   rure_find          -> Rure.find, returns the leftmost-first span
   rure_find_bytes is not exposed: haystacks here are UTF-8 strings.
*/
