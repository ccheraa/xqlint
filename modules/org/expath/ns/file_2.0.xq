xquery version "3.0";

(:
 : Copyright 2006-2009 The FLWOR Foundation.
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 : http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :)

(:~
 : This module implements the file API EXPath specification available at http://expath.org/spec/file
 : @author Gabriel Petrovay, Matthias Brantner, Markus Pilman
 : @see http://expath.org/spec/file
 :)
module namespace file = "http://expath.org/ns/file";

import schema namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace an = "http://www.zorba-xquery.com/annotations";
declare namespace ver = "http://www.zorba-xquery.com/options/versioning";
declare option ver:module-version "2.0";

(:~
 : Appends a sequence of items to a file. If the file pointed by <pre>$file</pre>
 : does not exist, a new file will be created. Before writing to the file, the items
 : are serialized according to the <pre>$serializer-params</pre>.
 :
 : The semantics of <pre>$serializer-params</pre> is the same as for the
 : <pre>$params</pre> parameter of the <a target="_blank"
 : href="http://www.w3.org/TR/xpath-functions-11/#func-serialize">fn:serialize</a>
 : function.
 :
 : @param $file The path/URI of the file to write the content to.
 : @param $content The content to be serialized to the file.
 : @param $serializer-params Parameter to control the serialization of the
 :    content.
 : @return The empty sequence.
 : @error file:FOFL0004 If <pre>$file</pre> points to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:sequential function file:append(
  $file as xs:string,
  $content as item()*,
  $serializer-params as element(output:serialization-parameters)?
) as empty-sequence()
{
  file:append-text(
    $file,
    fn:serialize($content, $serializer-params))
};

(:~
 : Appends a sequence of Base64 items as binary to a file. If the file pointed
 : by <pre>$file</pre> does not exist, a new file will be created.
 :
 : @param $file The path/URI of the file to write the content to.
 : @param $content The content to be serialized to the file.
 : @return The empty sequence.
 : @error file:FOFL0004 If <pre>$file</pre> points to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:sequential function file:append-binary(
  $file as xs:string,
  $content as xs:base64Binary*
) as empty-sequence() external;

(:~
 : Appends a sequence of string items to a file.
 :
 : @param $file The path/URI of the file to write the content to.
 : @param $content The content to be serialized to the file.
 : @return The empty sequence.
 : @error file:FOFL0004 If <pre>$file</pre> points to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %private %an:sequential function file:append-text(
  $file as xs:string,
  $content as xs:string*
) as empty-sequence() external;

(:~
 : Copies a file or a directory given a source and a destination path/URI.
 :
 : @param $source The path/URI of the file or directory to copy.
 : @param $destination The destination path/URI.
 : @return The empty sequence.
 : @error file:FOFL0001 If the <pre>$source</pre> path does not exist.
 : @error file:FOFL0002 If the computed destination points to a file system item
 :    with a different type than the <pre>$source</pre>.
 : @error file:FOFL0003 If <pre>$destination</pre> does not exist and it's
 :    parent directory does not exist either.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic %an:sequential function file:copy(
  $source as xs:string,
  $destination as xs:string
) as empty-sequence()
{
  if (file:exists($source)) then
    if (file:is-directory($source)) then
      file:copy-directory-impl($source, $destination)
    else
      file:copy-file-impl($source, $destination)
  else
    fn:error(xs:QName("file:FOFL0001"), fn:concat("The source path does not exists: ", $source))
};

(:~
 : Copies a file given a source and a destination path/URI.
 :
 : @param $sourceFile The path/URI of the file to copy.
 : @param $destination The destination path/URI.
 : @return The empty sequence.
 : @error file:FOFL0001 If the <pre>$source</pre> path does not exist.
 : @error file:FOFL0002 If the computed destination points to directory.
 : @error file:FOFL0003 If <pre>$destination</pre> does not exist and it's
 :    parent directory does not exist either.
 : @error file:FOFL0004 If <pre>$sourceFile</pre> points to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %private %an:sequential function file:copy-file-impl(
  $sourceFile as xs:string,
  $destination as xs:string
) as empty-sequence() external;

(:~
 : Copies a source directory recursively to a destination path/URI.
 :
 : @param $sourceDir The path/URI of the directory to copy.
 : @param $destination The destination path/URI.
 : @return The empty sequence.
 : @error file:FOFL0001 If the <pre>$source</pre> path does not exist.
 : @error file:FOFL0002 If <pre>$destination</pre> points to an existing file.
 : @error file:FOFL0003 If <pre>$destination</pre> does not exist and it's
 :    parent directory does not exist either.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %private %an:nondeterministic %an:sequential function file:copy-directory-impl(
  $sourceDir as xs:string,
  $destination as xs:string
) as empty-sequence()
{
  if (file:is-file($destination)) then
    fn:error(xs:QName("file:FOFL0002"), fn:concat("The specified destination path already exists: ", $destination))
  else if (fn:not(file:exists($destination))) then
    let $dirname := file:dir-name($destination)
    return
      if (fn:not(file:exists($dirname))) then
        fn:error(xs:QName("file:FOFL0003"), fn:concat("The destination directory does not exist: ", $dirname))
      else
        {
          file:create-directory($destination);
          file:copy-directory-content($sourceDir, $destination)
        }

  else
    let $basename := file:base-name($sourceDir)
    let $newdir := fn:concat($destination, file:directory-separator(), $basename)
    return
      {
        file:create-directory($newdir);
        file:copy-directory-content($sourceDir, $newdir)
      }
};

(:~
 : Copies the content of a given directory to an existing destination
 : directory.
 :
 : @param $sourceDir The path/URI of the directory to copy the content from.
 : @param $destination The destination directory path/URI.
 : @return The empty sequence.
 : @error file:FOFL0001 If the <pre>$source</pre> path does not exist.
 : @error file:FOFL0003 If <pre>$destination</pre> directory does not exist.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %private %an:nondeterministic %an:sequential function file:copy-directory-content(
  $sourceDir as xs:string,
  $destination as xs:string
) as empty-sequence()
{
  if (file:is-directory($destination)) then
    for $item in file:list($sourceDir)
    let $fullPath := fn:concat($sourceDir, file:directory-separator(), $item)
    return
      file:copy($fullPath, $destination)
  else
    fn:error(xs:QName("file:FOFL0003"), fn:concat("The specified destination directory does not exist: ", $destination))    
};

(:~
 : Creates a directory.
 :
 : The operation is will create all the missing parent directories from the
 : given path.
 :
 : @param $dir The path/URI denoting the directory to be created.
 : @return The empty sequence.
 : @error file:FOFL0002 If the directory cannot be created because of an already
 :    existing file.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:sequential function file:create-directory(
  $dir as xs:string
) as empty-sequence() external;

(:~
 : Deletes a file or a directory from the file system.
 :
 : If <pre>$path</pre> points to a directory the directory will be deleted
 : recursively.
 :
 : @param $path The path/URI of the file or directory to delete.
 : @return The empty sequence.
 : @error file:FOFL0001 If the <pre>$path</pre> path does not exist.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic %an:sequential function file:delete(
  $path as xs:string
) as empty-sequence()
{
  if (file:exists($path)) then
    if (file:is-directory($path)) then
      file:delete-directory-impl($path)
    else
      file:delete-file-impl($path)
  else
    fn:error(xs:QName("file:FOFL0001"), fn:concat("The path does not exists: ", $path))
};

(:~
 : Deletes a file from the file system.
 :
 : @param $file The path/URI of the file to delete.
 : @return The empty sequence.
 : @error file:FOFL0001 If the <pre>$file</pre> path does not exist.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %private %an:sequential function file:delete-file-impl(
  $file as xs:string
) as empty-sequence() external;

(:~
 : Deletes a directory from the file system.
 :
 : @param $dir The path/URI of the directory to delete.
 : @return The empty sequence.
 : @error file:FOFL0001 If the <pre>$dir</pre> path does not exist.
 : @error file:FOFL0003 If <pre>$dir</pre> does not point to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %private %an:nondeterministic %an:sequential function file:delete-directory-impl(
  $dir as xs:string
) as empty-sequence()
{
  for $item in file:list($dir)
  let $fullPath := fn:concat($dir, file:directory-separator(), $item)
  return
    if (file:is-directory($fullPath)) then
      file:delete-directory-impl($fullPath);
    else
      file:delete-file-impl($fullPath);
    
  file:delete-file-impl($dir)
};

(:~
 : Tests if a path/URI is already used in the file system.
 :
 : @param $path The path/URI to test for existence.
 : @return true if the path/URI points to an existing file system item.
 :)
declare %an:nondeterministic function file:exists(
  $path as xs:string
) as xs:boolean external;

(:~
 : Tests if a path/URI points to a directory. On UNIX-based systems, the root
 : and the volume roots are considered directories.
 :
 : @param $dir The path/URI to test.
 : @return true if the path/URI points to a directory.
 :)
declare %an:nondeterministic function file:is-directory(
  $dir as xs:string
) as xs:boolean external;

(:~
 : Tests if a path/URI points to a file.
 :
 : @param $dir The path/URI to test.
 : @return true if the path/URI points to a file.
 :)
declare %an:nondeterministic function file:is-file(
  $file as xs:string
) as xs:boolean external;

(:~
 : Moves a file or directory given a source and a destination paths/URIs.
 :
 : @param $source The path/URI of the file to move.
 : @param $destination The destination path/URI.
 : @return The empty sequence.
 : @error file:FOFL0001 If the <pre>$source</pre> path does not exist.
 : @error file:FOFL0002 If <pre>$source</pre> points to a directory and
 :    <pre>$destination</pre> points to an existing file.
 : @error file:FOFL0003 If <pre>$destination</pre> does not exist and it's parent
 :    directory does not exist either.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:sequential function file:move(
  $source as xs:string,
  $destination as xs:string
) as empty-sequence()
{
  file:copy($source, $destination);
  file:delete($source);
};

(:~
 : Reads the content of a file and returns a Base64 representation of the
 : content.
 :
 : @param $file The file to read.
 : @return The content of the file as Base64.
 : @error file:FOFL0001 If the <pre>$source</pre> path does not exist.
 : @error file:FOFL0004 If <pre>$source</pre> points to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic function file:read-binary(
  $file as xs:string
) as xs:base64Binary external;

(:~
 : Reads the content of a file and returns a string representation of the
 : content.
 :
 : The operation is equivalent to calling:
 : <pre>file:read-text($file, "UTF-8")</pre>.
 :
 : @param $file The file to read.
 : @return The content of the file as string.
 : @error file:FOFL0001 If the <pre>$source</pre> path does not exist.
 : @error file:FOFL0004 If <pre>$source</pre> points to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic function file:read-text(
  $file as xs:string
) as xs:string
{
  file:read-text($file, "UTF-8")
};

(:~
 : Reads the content of a file using the specified encoding and returns a
 : string representation of the content.
 :
 : In Zorba only the following encodings are currently supported: "UTF-8",
 : "UTF8". The encoding parameter is case insensitive.
 :
 : @param $file The file to read.
 : @param $encoding The encoding used when reading the file.
 : @return The content of the file as string.
 : @error file:FOFL0001 If the <pre>$source</pre> path does not exist.
 : @error file:FOFL0004 If <pre>$source</pre> points to a directory.
 : @error file:FOFL0006 If <pre>$encoding</pre> is not supported.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic function file:read-text(
  $file as xs:string,
  $encoding as xs:string
) as xs:string external;

(:~
 : Reads the content of a file and returns a sequence of strings representing
 : the lines in the content of the file.
 :
 : The operation is equivalent to calling:
 : <pre>file:read-text-lines($file, "UTF-8")</pre>.
 :
 : @param $file The file to read.
 : @return The content of the file as a sequence of strings.
 : @error file:FOFL0001 If the <pre>$source</pre> path does not exist.
 : @error file:FOFL0004 If <pre>$source</pre> points to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic function file:read-text-lines(
  $file as xs:string
) as xs:string*
{
  file:read-text-lines($file, "UTF-8")
};

(:~
 : Reads the content of a file using the specified encoding and returns a
 : sequence of strings representing the lines in the content of the file.
 :
 : This implementation considers the LF (&#xA;) character as the line
 : separator. If a resulting line ends with the CR (&#xD;) character, this is
 : trimmed as well. This implementation will uniformly treat LF and CRLF as
 : line separators.
 :
 : In Zorba only the following encodings are currently supported: "UTF-8",
 : "UTF8". The encoding parameter is case insensitive.
 :
 : @param $file The file to read.
 : @param $encoding The encoding used when reading the file.
 : @return The content of the file as a sequence of strings.
 : @error file:FOFL0001 If the <pre>$source</pre> path does not exist.
 : @error file:FOFL0004 If <pre>$source</pre> points to a directory.
 : @error file:FOFL0006 If <pre>$encoding</pre> is not supported.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic function file:read-text-lines(
  $file as xs:string,
  $encoding as xs:string
) as xs:string* external;

(:~
 : This is an internal function that copies an entire source directory to an
 : destination directory. The caller to this function must make sure that both
 : the source and destination point to existing directories.
 :
 : @param $sourceDir The existing source directory.
 : @param $destinationDir The existing destination directory.
 : @return The empty sequence.
 :)
declare %private %an:nondeterministic %an:sequential function file:copy-directory(
  $sourceDir as xs:string,
  $destinationDir as xs:string
) as empty-sequence()
{
  let $name := file:base-name($sourceDir)
  let $destDir := fn:concat($destinationDir, file:directory-separator(), $name)
  return
    {
      file:create-directory($destDir);

      for $item in file:list($sourceDir)
      let $fullSrcPath := fn:concat($sourceDir, file:directory-separator(), $item)
      let $fullDestPath := fn:concat($destDir, file:directory-separator(), $item)
      return
        if (file:is-directory($fullSrcPath)) then
          file:copy-directory($fullSrcPath, $fullDestPath)
        else
          file:copy($fullSrcPath, $fullDestPath)
    }
};

(:~
 : Writes a sequence of items to a file. Before writing to the file, the items
 : are serialized according to the <pre>$serializer-params</pre>.
 :
 : The semantics of <pre>$serializer-params</pre> is the same as for the
 : <pre>$params</pre> parameter of the <a target="_blank"
 : href="http://www.w3.org/TR/xpath-functions-11/#func-serialize">fn:serialize</a>
 : function.
 :
 : @param $file The path/URI of the file to write the content to.
 : @param $content The content to be serialized to the file.
 : @param $serializer-params Parameter to control the serialization of the
 :        content.
 : @return The empty sequence.
 : @error file:FOFL0004 If <pre>$file</pre> points to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:sequential function file:write(
  $file as xs:string,
  $content as item()*,
  $serializer-params as element(output:serialization-parameters)?
) as empty-sequence()
{
  file:write-text($file, fn:serialize($content, $serializer-params))
};

(:~
 : Writes a sequence of Base64 items as binary to a file.
 :
 : @param $file The path/URI of the file to write the content to.
 : @param $content The content to be serialized to the file.
 : @return The empty sequence.
 : @error file:FOFL0004 If <pre>$file</pre> points to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:sequential function file:write-binary(
  $file as xs:string,
  $content as xs:base64Binary*
) as empty-sequence() external;

(:~
 : Writes a sequence of string items to a file.
 :
 : The operation is equivalent to calling:
 : <pre>file:write-text($file, $content, fn:true())</pre>.
 :
 : @param $file The path/URI of the file to write the content to.
 : @param $content The content to be serialized to the file.
 : @return The empty sequence.
 : @error file:FOFL0004 If <pre>$file</pre> points to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %private %an:sequential function file:write-text(
  $file as xs:string,
  $content as xs:string*
) as empty-sequence() external;

(:~
 : Lists the file system items in a certain directory.
 :
 : The operation is equivalent to calling:
 : <pre>file:list($dir, fn:false())</pre>.
 :
 : @param $dir The path/URI of the directory to retrieve the children from.
 : @return The sequence of names of the direct children.
 : @error file:FOFL0003 If <pre>$dir</pre> does not point to an existing directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic function file:list(
  $dir as xs:string
) as xs:string* external;

(:~
 : Lists the file system items in a certain directory. The order of the items
 : in the resulting sequence is not defined. The "." and ".." items are not
 : returned. The returned paths are relative to the provided <pre>$path</pre>.
 :
 : If <pre>$recursive</pre> evaluates to <pre>fn:true()</pre>, the operation
 : will recurse in the subdirectories.
 : 
 : @param $dir The path/URI to retrieve the children from.
 : @param $recursive A boolean flag indicating whether the operation should be
 :    performed recursively.
 : @return A sequence of relative paths.
 : @error file:FOFL0003 If <pre>$dir</pre> does not point to an existing directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic function file:list(
  $path as xs:string,
  $recursive as xs:boolean
) as xs:string*
{
  for $f in file:list($path)
  let $full := fn:concat($path, file:directory-separator(), $f)
  return (
    $f,
    if ($recursive and file:is-directory($full) and not($f = (".","..") )) then
      for $child in file:list($full, $recursive)
      return fn:concat($f, file:directory-separator(), $child)
    else
      ()
  )
};

(:~
 : Lists all files matching the given pattern in a given directory.
 : The order of the items in the result is not defined.
 : The "." and ".." items are not considered for the match.
 : The file paths are relative to the provided $path.
 :
 : The pattern is a glob expression supporting:
 : <ul>
 :   <li><pre>*</pre> for matching any number of unknown characters</li>
 :   <li><pre>?</pre> for matching one unknown character</li>
 : </ul>
 : 
 : @param $path The path/URI to retrieve the children from.
 : @param $recursive A boolean flag indicating whether the operation should be
 :    performed recursively.
 : @param $pattern The file name pattern.
 : @return A sequence of file names matching the pattern.
 : @error file:FOFL0003 If <pre>$dir</pre> does not point to an existing directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic function file:list(
  $path as xs:string,
  $recursive as xs:boolean,
  $pattern as xs:string
) as xs:string* {
  for $file in file:list($path, $recursive)
  let $name := fn:tokenize($file, fn:concat("\", file:directory-separator()))[fn:last()]
  return
    if (fn:matches($name, file:glob-to-regex($pattern))) then
      $file
    else
      ()
};

(:~
 : A helper function that performs a trivial (not complete) glob to regex
 : pattern translation.
 : 
 : @param $pattern The glob pattern.
 : @return A regex pattern corresponding to the glob pattern provided.
 :)
declare function file:glob-to-regex(
  $pattern as xs:string
) as xs:string {
  let $pattern := fn:replace($pattern, '(\.|\[|\]|\\|/|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
  let $pattern := fn:replace($pattern, '\\\?', '.')
  let $pattern := fn:replace($pattern, '\\\*', '.*')
  return
    fn:concat("^", $pattern, "$")
};

(:~
 : Retrieves the timestamp of the last modification of the file system item
 : pointed by the path/URI.
 :
 : @param $path The file system item to read the last modification
 :    timestamp from.
 : @return The date and time of the last modification of the item.
 : @error file:FOFL0001 If the <pre>$path</pre> does not exist.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic function file:last-modified(
  $path as xs:string
) as xs:dateTime external;

(:~
 : Retrieves the size of a file.
 :
 : @param $file The file get the size.
 : @return An integer representing the size in bytes of the file.
 : @error file:FOFL0001 If the <pre>$file</pre> does not exist.
 : @error file:FOFL0004 If the <pre>$file</pre> points to a directory.
 : @error file:FOFL9999 If any other error occurs.
 :)
declare %an:nondeterministic function file:size(
  $file as xs:string
) as xs:integer external;

(:~
 : This function returns the value of the operating system specific directory
 : separator. For example, <pre>/</pre> on UNIX-based systems and <pre>\</pre>
 : on Windows systems.
 :
 : @return The operating system specific directory separator.
 :)
declare function file:directory-separator() as xs:string external;

(:~
 : This function returns the value of the operating system specific path
 : separator. For example, <pre>:</pre> on UNIX-based systems and <pre>;</pre>
 : on Windows systems.
 :
 : @return The operating system specific path separator.
 :)
declare function file:path-separator() as xs:string external;

(:~
 : Transforms a relative path/URI into an absolute operating system path by
 : resolving it against the current working directory.
 :
 : No path existence check is made.
 :
 : @param $path The path/URI to transform.
 : @return The operating system file path.
 :)
declare function file:resolve-path(
  $path as xs:string
) as xs:string external;

(:~
 : Transforms a file system path into a URI with the file:// scheme. If the
 : path is relative, it is first resolved against the current working
 : directory.
 :
 : No path existence check is made.
 :
 : @param $path The path to transform.
 : @return The file URI corresponding to <pre>path</pre>.
 :)
declare function file:path-to-uri(
  $path as xs:string
) as xs:anyURI external;

(:~
 : Transforms a URI, an absolute path, or relative path to a native path on the
 : running platform.
 :
 : No path existence check is made.
 :
 : @param $path The uri or path to normalize.
 : @return The native path corresponding to <pre>$path</pre>.
 : @error file:FOFL9999 If an error occurs while trying to obtain the native path.
 :)
declare function file:path-to-native($path as xs:string) as xs:string external;

(:~
 : Returns the last component from the <pre>$path</pre>, deleting any
 : trailing directory-separator characters. If <pre>$path</pre> consists
 : entirely directory-separator characters, the empty string is returned. If
 : <pre>$path</pre> is the empty string, the string <pre>"."</pre> is returned,
 : signifying the current directory.
 :
 : No path existence check is made.
 :
 : @param $path A file path/URI.
 : @return The base name of this file.
 :)
declare function file:base-name($path as xs:string) as xs:string
{
  let $delim := file:directory-separator()
  let $escapedDelim :=
    if ($delim eq "/") then
      $delim
    else
      fn:concat("\", $delim)
  let $normalized-file := 
    let $n := file:prepare-for-dirname-and-base-name($path)
    return if ($delim eq "\" and fn:matches($n, "^[a-zA-Z]:$")) then
      fn:concat($n, "\")
    else $n
  return
    if (fn:matches($path, fn:concat("^", $escapedDelim, "+$"))) then
      ""
    else if ($delim eq "\" and fn:matches($path, "^[a-zA-Z]:\\?$")) then
      ""
    else if ($path eq "") then
      "."
    else
      fn:replace($normalized-file, fn:concat("^.*", $escapedDelim), "")
};

(:~
 : Returns the last component from the <pre>$path</pre>, deleting any
 : trailing directory-separator characters and the <pre>$suffix</pre>. If path
 : consists entirely directory-separator characters, the empty string is
 : returned. If path is the empty string, the string <pre>"."</pre> is
 : returned, signifying the current directory.
 :
 : No path existence check is made.
 :
 : The <pre>$suffix</pre> can be used for example to eliminate file extensions.
 :
 : @param $path A file path/URI.
 : @param $suffix A suffix which should get deleted from the result.
 : @return The base-name of $path with a deleted $suffix.
 :)
declare function file:base-name($path as xs:string, $suffix as xs:string) as xs:string
{
  let $res := file:base-name($path)
  return
    if (fn:ends-with($res, $suffix) and $res ne ".") then
      fn:substring($res, 1, fn:string-length($suffix))
    else
      $res
};

(:~
 : This function is the converse of <pre>file:base-name</pre>. It returns a
 : string denoting the parent directory of the <pre>$path</pre>. Any trailing
 : directory-separator characters are not counted as part of the directory
 : name. If path is the empty string or contains no directory-separator string,
 : <pre>"."</pre> is returned, signifying the current directory.
 :
 : No path existence check is made.
 :
 : @param $path The filename, of which the dirname should be get.
 : @return The name of the directory the file is in.
 :)
declare function file:dir-name($path as xs:string) as xs:string
{
  let $delim := file:directory-separator()
  let $escapedDelim :=
    if ($delim eq "/") then
      $delim
    else
      fn:concat("\", $delim)
  let $normalized-file := file:prepare-for-dirname-and-base-name($path)
  return
    if (fn:matches($path, fn:concat("^", $escapedDelim, "+$"))) then
      $delim
    else if ($normalized-file eq $delim) then
      $delim
    else if ($delim eq "\" and fn:matches($path, "^[a-zA-Z]:\\$")) then
      $path
    else if ($delim eq "\" and fn:matches($normalized-file, "^[a-zA-Z]:$")) then
      fn:concat($normalized-file, '\')
    else if ($path eq "") then
      "."
    else if (fn:matches($normalized-file, $escapedDelim)) then
      fn:replace($normalized-file, fn:concat("^(.*)", $escapedDelim, ".*"), "$1")
    else
      "."
};

(:~
 : This is a helper function used by dirname and base-name. This function takes a path as
 : input and normalizes it according to the rules states in dirname/base-name documentation
 : and normalizes it to a system specific path.
 :)
declare %private function file:prepare-for-dirname-and-base-name($path as xs:string) as xs:string
{
  let $delim := file:directory-separator()
  let $escapedDelim :=
    if ($delim eq "/") then
      $delim
    else
      fn:concat("\", $delim)
  let $normalize-path := file:path-to-native($path)
  let $normalized :=
    if ($normalize-path eq $delim) then
      $normalize-path
    else
      fn:replace($normalize-path, fn:concat($escapedDelim, "+$"), "")
  return $normalized
};
