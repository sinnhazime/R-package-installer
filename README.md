# R Package Installer

v0.1.0

## 概要

ネット環境のないサーバーにRのパッケージを依存パッケージを含めてインストールするために、必要な依存パッケージ群を含むローカルリポジトリを作成します。

CRAN, Bioconductorのパッケージに対応しています。

stringiパッケージは本来インストールのためにインターネットアクセスが必要ですが、stringi開発者の解説に従って、インターネットアクセスがない場合でもインストール可能なファイルに自動的に変換します。(参照: https://github.com/gagolews/stringi/blob/master/INSTALL)

## 手順

1. 自分のマシンでmake_local_repo.Rを実行
2. 出力ディレクトリ(デフォルトでは`r_repos`)をサーバーにアップロード
3. make_local_repo.Rの指示通り、サーバーでinstall.packages("<YOUR_PACKAGES>", type = "<YOUR_TYPE>", repo = "file://<OUTPUT_PATH>")を実行

## 注意

* 必要なパッケージ(optparse, miniCRAN, BiocManager)がインストールされていない場合、自動でインストールします。パッケージ環境などを管理している方は自分で先にインストールしてください。
* miniCRANの依存パッケージopenssl, curlのインストールでコケる場合があります。例えばUbuntuの場合、先に`sudo apt install libssl-dev libcurl4-openssl-dev`をしておく必要があります。ご自身の環境に従ってインストールしてください。
* BiocManagerが入っていない状態でBioconductorのバージョンを指定しなかった場合、BiocManagerをインストール後エラーを吐いて終了します。インストールされたBioconductorのバージョンをデフォルト値として使って良い場合はそのまま再度ランしてください。またはBioconductorのバージョンを指定してランし直してください。

## History

  [2020/6/15] v0.1.0
* これまでのファイルをdeprecatedに変更。make_local_repo.Rを新たに作成。

[2020/5/1] v0.0.4
* bug fix
* 依存パッケージが存在しないパッケージを指定した場合に、そのパッケージがダウンロード対象から漏れてしまう不具合を修正

[2020/4/21] v0.0.3
* r_pkg_download.shはr_pkg_download.Rのあるディレクトリで実行する必要があったのを自由に
* r_pkg_install.shはr_pkg_check_installed.Rのあるディレクトリで実行する必要があったのを自由に
* r_pkg_download.Rで指定するパラメータをすべてr_pkg_download.shに移動
* tarへの圧縮・解凍を自動で行うよう変更
* fsパッケージへの依存を削除

[2020/4/12] v0.0.2
* MACの場合によしなにコードを変えるように変更
* サーバー側でまだインストールされていない依存パッケージのみをインストールするように変更

[2020/4/8] v0.0.1
* First release