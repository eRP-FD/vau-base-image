# gpg keys

The following keys are needed for gpg file verification:

* `mainline.gpg`: Mainline kernel verification

This key was downloaded with:

```
gpg --keyserver hkps://keyserver.ubuntu.com --recv-key 60AA7B6F30434AE68E569963E50C6A0917C622B0 && \
gpg --armor --export 60AA7B6F30434AE68E569963E50C6A0917C622B0
```

as hinted in [the mainline documentation](https://wiki.ubuntu.com/Kernel/MainlineBuilds#Verifying_mainline_build_binaries).
