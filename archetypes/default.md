---
title: "{{ replace .Name "-" " " | title }}"
slug: ""  # set a latin, dash-separated slug, e.g. my-post-title
date: {{ now.Format "2006-01-02" }}
categories: []
draft: false
tags: []
description: ""
# For posts with images use a leaf bundle (index.md) and uncomment,
# substituting the real asset directory:
# images:
# - /img/<dir>/cover.webp
# featuredimage: /img/<dir>/cover.webp
---

