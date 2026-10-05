# 4Dセッション：デスクトップからWebまでを1つの共有セッションで

4D Sessions: From Desktop to Web in a Single Shared Session (Technical Note 26-06): Japanese edition.

このテクニカルノートでは、4Dのデスクトップアプリケーションで開いたセッションを、OTP（ワンタイムパスワード）付きのURLを使ってWebブラウザーやスマートフォンと共有する方法を説明します。**Session.info**によるセッション情報の取得、**Session.createOTP()**によるトークンの発行、**Session.storage**によるデバイス間の状態共有、権限の付与と解除を、本人確認ワークフローのデモ「4D Secure OTP」を通して解説します。デモでは、デスクトップから共有したセッションにQRコードでスマートフォンを接続し、チャレンジの数字に答えて本人確認を行い、権限で保護された写真のアップロードとオペレーターによる判定までを体験できます。

This is the Japanese edition of 4D Technical Note 26-06 and its companion demo. It shows how to share a 4D desktop session with a browser and a phone through OTP-linked URLs. It covers Session.info, Session.createOTP(), Session.storage and privileges, illustrated by an identity-verification demo.

## Download

| | |
|---|---|
| PDF (Japanese) | [26-06_4DSessions_ja.pdf](https://github.com/miyako/4DSessions/releases/latest/download/26-06_4DSessions_ja.pdf) |
| 4D demo | [4DSessions.zip](https://github.com/miyako/4DSessions/releases/latest/download/4DSessions.zip) |
| Original (English) | `document/26-06_4DSessions.pdf` |

## Demo

- 4D version: 4D 21 R3 or later
- Open `demo/4DSessions/Project/4DSessions.4DProject`.
- Languages: English and Japanese. The desktop UI follows the system language; the web pages follow the browser language (`Accept-Language`). The XLIFF files are in `Resources/<lang>.lproj/`.
- The start screen opens at startup. **デモを起動** opens the session window; the web server must be running. **このセッションを共有** creates the OTP and opens the dashboard in the browser.

## Differences from the original

- Screenshots of the demo were replaced with Japanese captures (figures 1, 2, 4, 5, 6, 8 and 9). Figures 3 and 7 are kept as in the original.
- The demo is localised in English and Japanese: forms, messages and web pages (XLIFF).
- Activity log entries and case messages are stored as XLIFF IDs with parameters and translated when displayed. The code extract in the note, `Session.storage.data.message:="Identity confirmed. Please upload your photo."`, is kept as in the original; the demo now stores `"Msg_IdentityConfirmed"`.
- The start screen and the session window open without blocking, and an open window is brought to the front instead of being opened twice.
- The Docs and Blog links on the start screen open the Japanese pages.

## Editing and rebuilding

The PDF is generated from plain-text sources. Edit them and run `make`.

| File | What |
|---|---|
| `src/ja.md` | Translated body text. **Don't touch code blocks** (`make check` verifies them). |
| `figures/layout/fig-NN.json` | Per-figure settings; `"replace"` uses a ready-made image (`figures/fig-NN-ja.png`) |
| `glossary.md` | Terminology |

```sh
make            # check → figures → build/26-06_4DSessions_ja.pdf
make check      # code blocks unchanged, figure references complete
make review     # contact sheets of the figures (build/contact-N.png)
make release-assets
```

Requirements: Python 3, Google Chrome, CJK fonts, and Tesseract (only needed for re-extraction).
See the [localisation template](https://github.com/miyako/4d-technote-localisation-template) for the full workflow.

## Credits

- Original: Al Mahdi Bakkali, Technical Support Engineer, 4D Inc. (Technical Note 26-06)
- Produced with [4d-technote-localisation-template](https://github.com/miyako/4d-technote-localisation-template) and GitHub Copilot.
