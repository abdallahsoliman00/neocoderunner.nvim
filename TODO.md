Here, new features, or in general, ideas are simply written down.

# TODO

- Make a global configuration for the runners where the user can set the default runners globally for their profile in the config for the plugin.
- When running a snippet, make the run code indent agnostic.
    What this means is that if we want to run the first two lines in the function:
    ```python
    def foo():
        a, b = 2,3
        print(a+b)
    ```
    all we need to do is highlight and run. What currently happens is that you need to unindent the two lines before highlighting and running them.

    An LSP can also be used to auto import the required packages or libraries into the temp runner file from the current envirenment, though this could prove to be difficult.

- Make a logo
