# sybで遊ぶ

[![Deploy](https://github.com/toku-sa-n/playing-with-syb/actions/workflows/ci.yml/badge.svg)](https://github.com/toku-sa-n/playing-with-syb/actions/workflows/ci.yml)

[English version is here.](README.en.md)

## はじめに

この記事は，[Haskell Advent Calendar 2022](https://qiita.com/advent-calendar/2022/haskell)の20日目の記事です．

この記事では，Haskellライブラリの一つである[syb](https://hackage.haskell.org/package/syb-0.7.2.2)の簡単な紹介と，実際に私がプロジェクトの中で使用した例を紹介します．

## ライセンス

本文は[CC BY 4.0](LICENSE-CC-BY-4.0.md)の下で利用可能です．またソースコードは[WTFPL](LICENSE-WTFPL.md)の下で利用可能です．

## バージョン情報

| 名前                        | バージョン                    |
|-----------------------------|-------------------------------|
| Stack                       | 2.9.1                         |
| Stack resolver              | LTS 20.4                      |
| GHCやライブラリのバージョン | LTSで指定されているものを使用 |

## `syb`とは

`syb`とはScrap Your Boilerplateの略です．[`Data`](https://hackage.haskell.org/package/base-4.16.4.0/docs/Data-Data.html#t:Data)型クラスや[`Typeable`](https://hackage.haskell.org/package/base-4.16.4.0/docs/Data-Typeable.html#t:Typeable)を利用して，データ構造に含まれている特定の型の値だけに対して操作を行ったり，特定の型の値だけを抽出するなどといったことが可能になります．

[Haskell Wiki](https://wiki.haskell.org/Research_papers/Generics)にいくつか論文が紹介されていますが，特に[Scrap Your Boilerplate: A Practical Design Pattern for Generic Programming](https://www.microsoft.com/en-us/research/wp-content/uploads/2003/01/hmap.pdf)は読みやすいのでおすすめです．

## コード例

以下の説明では，以下の，様々な世界に住む住民や集団の情報を一つのデータ構造に含めたものを用います．

```haskell
{-# LANGUAGE DeriveDataTypeable  #-}
{-# LANGUAGE PatternSynonyms     #-}
{-# LANGUAGE RankNTypes          #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications    #-}
{-# LANGUAGE TypeFamilies        #-}

module Lib
    ( gfoldlMember
    , testMembersFromWorld
    , testMembersFromWorldWithListify
    , testListMossalcadiaMania
    , testSummonAllGroupsInKumamotoCastle
    , testAppendWorldForData
    , testAllNothing
    ) where

import           Data.Data             (Data)
import           Data.Generics.Aliases (mkT)
import           Data.Generics.Schemes (everywhere, listify)
import           Data.List             (nub)
import           Test.Hspec            (Spec, describe, it, shouldBe)
import           Type.Reflection       (eqTypeRep, pattern App, typeRep,
                                        (:~~:) (HRefl))

data World =
    World
        { worldName :: String
        , groups    :: [Group]
        }
    deriving (Data, Eq)

data Group =
    Group
        { groupName :: String
        , place     :: String
        , members   :: [Member]
        }
    deriving (Data, Eq)

data Member =
    Member
        { memberName   :: String
        , anotherName  :: String
        , age          :: Maybe Int
        , favoriteMoss :: Maybe String
        }
    deriving (Data, Eq, Show)

worlds :: [World]
worlds =
    [ World
          { worldName = "イルヴァ"
          , groups =
                [ Group
                      { groupName = "エレア"
                      , place = "ノースティリス"
                      , members =
                            [ Member
                                  { memberName = "ロミアス"
                                  , anotherName = "異形の森の使者"
                                  , age = Just 24
                                  , favoriteMoss = Nothing
                                  }
                            , Member
                                  { memberName = "ラーネイレ"
                                  , anotherName = "風を聴く者"
                                  , age = Just 22
                                  , favoriteMoss = Nothing
                                  }
                            ]
                      }
                , Group
                      { groupName = "ヴェルニースの人達"
                      , place = "ヴェルニース"
                      , members =
                            [ Member
                                  { memberName = "ウェゼル"
                                  , anotherName = "ザナンの白き鷹"
                                  , age = Just 31
                                  , favoriteMoss = Nothing
                                  }
                            , Member
                                  { memberName = "ロイター"
                                  , anotherName = "ザナンの紅の英雄"
                                  , age = Just 32
                                  , favoriteMoss = Nothing
                                  }
                            ]
                      }
                ]
          }
    , World
          { worldName = "ざくざくアクターズの世界"
          , groups =
                [ Group
                      { groupName = "ハグレ王国"
                      , place = "ハグレ王国"
                      , members =
                            [ Member
                                  { memberName = "デーリッチ"
                                  , anotherName = "ハグレ王国国王"
                                  , age = Nothing
                                  , favoriteMoss = Nothing
                                  }
                            , Member
                                  { memberName = "ローズマリー"
                                  , anotherName = "ビッグモス"
                                  , age = Nothing
                                  , favoriteMoss = Just "モスアルカディア"
                                  }
                            ]
                      }
                ]
          }
    ]
```

## 下準備：`Data`型クラスの実装

`syb`を利用するためには，型が`Data`型クラスを実装している必要があります．`Data`型クラスの詳細についてはドキュメントを確認してください．

何はともあれまずは実装方法ですが，GHCの拡張機能である`DeriveDataTypeable`を有効にして，`deriving (Data)`で完了です．もちろん手動で実装することも可能ですが，deriveしたほうが楽です．

以下の説明は，型に対し`Data`型クラスが適切に実装されていることを前提としています．

## 使用例

### 特定の型の値だけを抽出する

例えば`World`に含まれている`Member`をすべて抽出する関数を書きたいとしましょう．そのような関数を単純に書くと，以下の`membersFromWorld`関数のようになります．

```haskell
membersFromWorld :: World -> [Member]
membersFromWorld = concatMap members . groups
```

簡単ですね．以下のテストコードで動作を確かめることができます．

（本来テストコードは別の場所に書くべきですが，ここではGHCiなどの出力を載せる代わりにテストコードで実際の挙動を示しています．CIでテストコードを実行しているので，LTSなどのバージョンを上げた際，仮に将来動作が変更されたとしても，それに気付けるようにしています）

```haskell
allMembersInWorld :: [Member]
allMembersInWorld =
    [ Member
          { memberName = "ロミアス"
          , anotherName = "異形の森の使者"
          , age = Just 24
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "ラーネイレ"
          , anotherName = "風を聴く者"
          , age = Just 22
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "ウェゼル"
          , anotherName = "ザナンの白き鷹"
          , age = Just 31
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "ロイター"
          , anotherName = "ザナンの紅の英雄"
          , age = Just 32
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "デーリッチ"
          , anotherName = "ハグレ王国国王"
          , age = Nothing
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "ローズマリー"
          , anotherName = "ビッグモス"
          , age = Nothing
          , favoriteMoss = Just "モスアルカディア"
          }
    ]

testMembersFromWorld :: Spec
testMembersFromWorld =
    describe "membersFromWorld" $
    it "`World`に含まれるすべての`Member`を返す．" $
    concatMap membersFromWorld worlds `shouldBe` allMembersInWorld
```

今回の場合，`World`の構造があまり複雑ではないため，いくつかの関数を用いて簡単に抽出することが出来ました．しかし，例えば`Maybe`が使われていたり，構造がもっと大きく複雑だったり，型引数が使用されていたりすると，今回のようにセレクタ関数を組み合わせて抽出する方法は難しくなります．

そのような場合，sybの[`listify`](https://hackage.haskell.org/package/syb-0.7.2.2/docs/Data-Generics-Schemes.html#v:listify)関数を用いるとすんなり書けます．

```haskell
membersFromWorldWithListify :: World -> [Member]
membersFromWorldWithListify = listify onlyMember
  where
    onlyMember :: Member -> Bool
    onlyMember = const True

testMembersFromWorldWithListify :: Spec
testMembersFromWorldWithListify =
    describe "membersFromWorldWithListify" $
    it "`membersFromWorld`と同じ機能を持つ" $
    concatMap membersFromWorldWithListify worlds `shouldBe`
    concatMap membersFromWorld worlds
```

`listify`関数は，抽出する値の条件を指定する関数を受け取り，「`Data`を実装する任意の型の値を受け取り，その値に含まれている値のうち，条件を満たす値をリストとして返す」関数を返します．

`listify`関数のシグネチャは`Typeable r => (r -> Bool) -> GenericQ [r]`となっています．この`r`が，最終的なリストの要素の型となります．すなわちこの関数が返す関数は，受け取った値に含まれている型`r`の値に対し，それが条件を満たすかどうかを確認しています．上記の場合，`const True`で常に`True`を返すことで，型`r`の値を常に抽出するするようにします．

なお，`GenericQ`は`forall a. Data a => a -> r`のエイリアスです．また，[ドキュメントに記載されている](https://hackage.haskell.org/package/base-4.16.3.0/docs/Data-Typeable.html)ように，GHC7.10以降，全ての型は自動で`Typeable`をderiveしているため，型変数などを用いていなければ基本的に`listify`を任意の型に対して使用することができると考えて大丈夫です．以下に引用します．

> Since GHC 7.10, all types automatically have Typeable instances derived. This is in contrast to previous releases where Typeable had to be explicitly derived using the DeriveDataTypeable language extension.

引数で抽出する条件を指定するため，例えばモスアルカディアが好きな人物だけを抽出することも可能です．

```haskell
listMossalcadiaMania :: World -> [Member]
listMossalcadiaMania = listify f
  where
    f :: Member -> Bool
    f = (== Just "モスアルカディア") . favoriteMoss

testListMossalcadiaMania :: Spec
testListMossalcadiaMania =
    describe "listMossalcadiaMania" $
    it "モスアルカディアが好きな`Member`をリストで返す" $
    concatMap listMossalcadiaMania worlds `shouldBe` expected
  where
    expected =
        [ Member
              { memberName = "ローズマリー"
              , anotherName = "ビッグモス"
              , age = Nothing
              , favoriteMoss = Just "モスアルカディア"
              }
        ]
```

### 特定の型の値を変更する

妙な話ですが，例えば全ての集団が突然熊本城に召喚されたとしましょう．`Group`の`place`を全て"熊本城"に変更しなければなりません．やはりこれも小規模のデータ構造ならいくつの関数を定義すればどうにかなります．しかし大規模なものになると手に負えません．

このような場合，`syb`で定義されている[`everywhere`](https://hackage.haskell.org/package/syb-0.7.2.2/docs/Data-Generics-Schemes.html#v:everywhere)を使うと楽に書けます．

```haskell
summonAllGroupsInKumamotoCastle :: World -> World
summonAllGroupsInKumamotoCastle = everywhere (mkT f)
  where
    f :: Group -> Group
    f x = x {place = "熊本城"}

testSummonAllGroupsInKumamotoCastle :: Spec
testSummonAllGroupsInKumamotoCastle =
    describe "summonAllGroupsInKumamotoCastle" $
    it "`World`のすべての`Group`の`place`を\"熊本城\"に設定する" $
    nub (fmap place $ listify f $ fmap summonAllGroupsInKumamotoCastle worlds) `shouldBe`
    ["熊本城"]
  where
    f :: Group -> Bool
    f = const True
```

`everywhere`は値を変更するための関数を受け取り，「`Data`を実装している任意の型の値を受け取り，それに含まれている全ての値に対して，先に受け取った関数を適用する」関数を返します．`fmap`のようなものです．

`everywhere`のシグネチャは`(forall a. Data a => a -> a) -> forall a. Data a => a -> a`となっています．`listify`の場合，引数の型は`Typeable r => (r -> Bool)`でしたので，単純に`Member -> Bool`などと，適当な型の値を受け取って`Bool`値を返す関数を渡せばよいのですが，`everywhere`は`Data`を実装する任意の型を受け取って，同じ型の値を返す関数を定義しなければならず，ある特定の型の値に対する操作を行うのは不可能のように見えます．

ここで利用するものが[`mkT`](https://hackage.haskell.org/package/syb-0.7.2.2/docs/Data-Generics-Aliases.html#v:mkT)です．`mkT`のシグネチャは`(Typeable a, Typeable b) => (b -> b) -> a -> a`ですが，この関数は，`b`型の値を受け取り，同じ型の値を返す関数を受け取り，それを`Typeable`な任意の型`a`の値を受け取り，同じ型の値を返す関数に拡張します．この際，受け取った値の型が実際には`b`である場合，受け取った関数を適用し，そうでなければ単純に受け取った値を返すようになります．以下に実行例を示します．

```haskell
appendWorld :: String -> String
appendWorld = (++ " World")

appendWorldForData :: Data a => a -> a
appendWorldForData = mkT appendWorld

testAppendWorldForData :: Spec
testAppendWorldForData =
    describe "appendWorldForData" $ do
        it "受け取った値の型が`String`なら，\" World\"を付加する" $
            appendWorldForData "Hello" `shouldBe` "Hello World"
        it "受け取った値の型が`String`ではないなら，受け取った値をそのまま返す" $
            appendWorldForData (3 :: Int) `shouldBe` 3
```

上記の熊本城の例では，関数`f :: Group -> Group`に`mkT`を適用したものを`everywhere`で使用しています．したがって，もし受け取った値の中に`Group`型の値が含まれているのならば，それの`place`を"熊本城"に変更します．別の型の値に対しては何も変更を加えません．

### 複雑な型に対応する

どういう理由かは知りませんが，突然全ての`Maybe a`を`Nothing`にしないといけなくなったとしましょう．単純に`mkT`に`f :: Data a => Maybe a -> Maybe a`という型の関数を渡すと失敗します．

```haskell
-- 以下のような関数は定義できない．
-- allNothing :: World -> World
-- allNothing = everywhere (mkT f)
--   where
--     f :: Data a => Maybe a -> Maybe a
--     f = const Nothing
```

正直なところ，私はこのエラーに対する正しい説明をすることが出来ません．ただし打開策は存在します．[`Type.Reflection`](https://hackage.haskell.org/package/base-4.16.3.0/docs/Type-Reflection.html#t:Typeable)モジュールを利用します．以下のように書くと目的を達成できます．なお，このコードの実行には`TypeApplications`，`ScopedTypeVariables`，`RankNTypes`を有効にする必要があります．

```haskell
allNothing :: Data a => a -> a
allNothing = everywhere f
  where
    f :: forall a. Data a => a -> a
    f x
        | App g _ <- typeRep @a
        , Just HRefl <- eqTypeRep g (typeRep @Maybe) = Nothing
        | otherwise = x

testAllNothing :: Spec
testAllNothing =
    describe "allNothing" $
    it "すべての`Maybe a`を`Nothing`にする" $
    allNothing allMembersInWorld `shouldBe` expected
  where
    expected =
        [ Member
              { memberName = "ロミアス"
              , anotherName = "異形の森の使者"
              , age = Nothing
              , favoriteMoss = Nothing
              }
        , Member
              { memberName = "ラーネイレ"
              , anotherName = "風を聴く者"
              , age = Nothing
              , favoriteMoss = Nothing
              }
        , Member
              { memberName = "ウェゼル"
              , anotherName = "ザナンの白き鷹"
              , age = Nothing
              , favoriteMoss = Nothing
              }
        , Member
              { memberName = "ロイター"
              , anotherName = "ザナンの紅の英雄"
              , age = Nothing
              , favoriteMoss = Nothing
              }
        , Member
              { memberName = "デーリッチ"
              , anotherName = "ハグレ王国国王"
              , age = Nothing
              , favoriteMoss = Nothing
              }
        , Member
              { memberName = "ローズマリー"
              , anotherName = "ビッグモス"
              , age = Nothing
              , favoriteMoss = Nothing
              }
        ]
```

`typeRep`を使用することで，型の構成を知ることができます．また，`eqTypeRep`は2つの型が等しいかどうかを確かめます．これが`Just HRefl`を返す場合，その2つの型は等しいとされます．

これらを用いることで，`everywhere`を使用する際に型変数を含む型に対しても操作を行うことができます．

## 実際のプロジェクトでの使用経験

現在私が行っている[HIndent](https://hackage.haskell.org/package/hindent)の[改修](https://github.com/mihaimaruseac/hindent/pull/593)において，ASTに対する前処理で`syb`の各関数を使用しています．

HIndentはHaskellのソースコードフォーマッタの一つです．現在の実装では，Haskellのソースコードをパースするために[haskell-src-exts](https://hackage.haskell.org/package/haskell-src-exts)を用いています．しかしながら，このライブラリは長らくメンテナンスされておらず，最近のGHCで導入された拡張機能などに対応することができません．したがってそのような拡張機能を利用しているコードをうまく整形できない問題がありました．

そこで，GHCのAPIを複数のGHCのバージョンで利用できるようにした[ghc-lib-parser](https://hackage.haskell.org/package/ghc-lib-parser)を利用するように，現在ソースコードを改修しています．

[`ghc-lib-parser`を用いてHaskellのソースコードをパースする](https://hackage.haskell.org/package/ghc-lib-parser-9.2.5.20221107/docs/GHC-Parser.html)と，[`HsModule`](https://hackage.haskell.org/package/ghc-lib-parser-9.2.5.20221107/docs/GHC-Hs.html#t:HsModule)という型の値を得ることができます．これはHaskellのソースコードのASTであり，これをもとにHIndentはコードの整形を行います．ただし，単純に生成されたASTを用いるとコメントの扱いが難しかったり，他にも整形において不便な事柄が存在します．そのため，適切なノードにコメントのノードを再配置するなど，ASTに対する前処理を行う必要があります．

`HsModule`は`Data`を実装しているため，`syb`の各関数を用いることができます．コメントノードの再配置の際は，まず[`listify`でコメントノードを回収](https://github.com/toku-sa-n/hindent/blob/afd30663dea44c1dd60d62f27cbe968d90544833/src/HIndent/ModulePreprocessing.hs#L42)します．このとき，コードの終端を表すために存在するEOFコメントノードは省いています．その後，コメントを適切に再配置しています．このとき`State`モナドも利用しているため，`everywhere`ではなく，モナドを扱うことができる[`everywhereM`関数](https://hackage.haskell.org/package/syb-0.7.2.2/docs/Data-Generics-Schemes.html#v:everywhereM)を使用しています（[コード例](https://github.com/toku-sa-n/hindent/blob/afd30663dea44c1dd60d62f27cbe968d90544833/src/HIndent/ModulePreprocessing/CommentRelocation.hs#L119-L128)）．

## 最後に

この記事では`syb`に関して簡単に説明しました．実際のところ，`Data`が実装されていて`Functor`が実装されていないという場合はあまりないと思います．だいたい`fmap`で事足ります．それでももしそのような状況に遭遇したら，`syb`のことを思い出してあげてください．

## 付録

### 付録A：なぜこのようなことが可能なのか

`syb`を初めて利用したときに，なぜ`listify`や`everywhere`などが実装可能なのか非常に気になりました．

その秘密は`Data`型クラスにあります．特に一番重要なメソッドが[`gfoldl`](https://hackage.haskell.org/package/base-4.16.3.0/docs/Data-Data.html#t:Data)です．`Member`型では`deriving (Data)`を用いていますが，おおよそ以下のような実装が生成されます（実際のメソッドの名前は`gfoldl`ですが，ここでは`gfoldlMember`としています）．

```haskell
gfoldlMember ::
       (forall d b. Data d =>
                        c (d -> b) -> d -> c b)
    -> (forall g. g -> c g)
    -> Member
    -> c Member
gfoldlMember k z Member {..} =
    z Member `k` memberName `k` anotherName `k` age `k` favoriteMoss
```

つまり，`Member`の各フィールドの値を畳み込むことが出来ます．

`syb`で定義されている各関数は直接`gfoldl`関数を用いているのではなく，この関数を用いている`Data`型クラスの他のメソッドを使用しています．

### 付録B：参考文献

- [`listify`の仕組みがわからない](https://tokuchan3515.hatenablog.com/entry/2022/07/15/182044)
- [How to collect `EpAnn`s from `Located HsModule`?](https://stackoverflow.com/questions/72947117/how-to-collect-epanns-from-located-hsmodule)
- [Matching higher-kinded types in SYB](https://stackoverflow.com/questions/60054686/matching-higher-kinded-types-in-syb)
- [Why does GHC complain about the missing `Typeable` instance even if I specify is as a type restriction?](https://stackoverflow.com/questions/73259681/why-does-ghc-complain-about-the-missing-typeable-instance-even-if-i-specify-is)
