import 'package:app/src/functions.dart';
import 'package:app/src/models/app_state_model.dart';
import 'package:app/src/models/category_model.dart';
import 'package:app/src/models/product_model.dart';
import 'package:app/src/resources/api_provider.dart';
import 'package:app/src/ui/blocks/blocks.dart';
import 'package:app/src/ui/blocks/place_selector.dart';
import 'package:app/src/ui/categories/categories.dart';
import 'package:app/src/ui/categories/expandable_category.dart';
import 'package:app/src/ui/checkout/order_summary.dart';
import 'package:app/src/ui/home/place_picker.dart';
import 'package:app/src/ui/pages/post_detail.dart';
import 'package:app/src/ui/products/products/product_list_page.dart';
import 'package:app/src/ui/products/products/products.dart';
import 'package:app/src/ui/vendor/ui/stores/stores.dart';
import 'package:app/src/ui/widgets/progress_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:scoped_model/scoped_model.dart';
import 'dart:io';
import 'package:app/src/ui/accounts/login/login.dart';
import 'package:app/src/ui/accounts/wishlist.dart';
import 'package:dunes_icons/dunes_icons.dart';
import 'package:app/src/ui/blocks/banners/on_click.dart';
import 'package:app/src/ui/products/product_detail/cart_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:url_launcher/url_launcher.dart';
import '../accounts/account/account.dart';
import '../pages/webview.dart';
import '../products/product_detail/product_detail.dart';
import './../../models/blocks_model.dart';
import './../checkout/cart/cart4.dart';
import './../home/search.dart';
import './../products/barcode_products.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'header_logo.dart';
import 'package:app/src/ui/accounts/firebase_chat/chat.dart';
import 'package:app/src/ui/blocks/banners/contact_form.dart';
import 'package:app/src/ui/checkout/cart/shopping_cart.dart';
import 'package:app/src/models/theme/bottom_navigation_bar.dart';
import 'package:app/src/ui/accounts/account/account_floating_button.dart';
import 'package:app/src/ui/accounts/orders/order_list.dart';
import 'package:app/src/ui/blocks/block_page.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/src/provider.dart';


const Color p = Color(0xff416d69);

//Color foreGroundColor = Colors.white;


final ZoomDrawerController z = ZoomDrawerController();

class ZoomDrawerPage extends StatefulWidget {
  const ZoomDrawerPage({Key? key}) : super(key: key);

  @override
  _ZoomDrawerPageState createState() => _ZoomDrawerPageState();
}

class _ZoomDrawerPageState extends State<ZoomDrawerPage> {

  AppStateModel appStateModel = AppStateModel();

  @override
  Widget build(BuildContext context) {

    Color backgroundColor = Theme.of(context).brightness == Brightness.dark ? Colors.black : appStateModel.blocks.settings.menuTheme.light.canvasColor;

    return ZoomDrawer(
      controller: z,
      borderRadius: 50,
      slideWidth: 310,
      mainScreenScale: 0.2,
      dragOffset: 10,
      style: DrawerStyle.defaultStyle,
      showShadow: true,
      moveMenuScreen: false,
      angle: 0.0,
      openCurve: Curves.linear,
      duration: const Duration(milliseconds: 500),
      menuBackgroundColor: backgroundColor,
      mainScreen: ZooDrawerApp(),
      menuScreen: MyDrawer(),
    );
  }
}

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> with SingleTickerProviderStateMixin {
  late AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    value: -1.0,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool get isPanelVisible {
    final AnimationStatus status = controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TwoPanels(
        controller: controller,
      ),
    );
  }
}

class TwoPanels extends StatefulWidget {
  final AnimationController controller;

  const TwoPanels({Key? key, required this.controller}) : super(key: key);

  @override
  _TwoPanelsState createState() => _TwoPanelsState();
}

class _TwoPanelsState extends State<TwoPanels> with TickerProviderStateMixin {
  ScrollController _scrollController = new ScrollController();
  AppStateModel appStateModel = AppStateModel();
  static const _headerHeight = 32.0;
  late TabController tabController = TabController(length: 3, vsync: this);
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..addListener(() {
    print("SlideValue: ${_controller.value} - ${_controller.status}");
  });
  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(1.5, 0.0),
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticIn,
  ));

  Animation<RelativeRect> getPanelAnimation(BoxConstraints constraints) {
    final _height = constraints.biggest.height;
    final _backPanelHeight = _height - _headerHeight;
    const _frontPanelHeight = -_headerHeight;

    return RelativeRectTween(
      begin: RelativeRect.fromLTRB(
        0.0,
        _backPanelHeight,
        0.0,
        _frontPanelHeight,
      ),
      end: const RelativeRect.fromLTRB(0.0, 100, 0.0, 0.0),
    ).animate(
      CurvedAnimation(parent: widget.controller, curve: Curves.linear),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreItems);
  }

  _loadMoreItems() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent && !appStateModel.loadingHomeProducts) {
        appStateModel.loadMoreRecentProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMoreItems);
    _scrollController.dispose();
    _controller.dispose();
    tabController.dispose();
    super.dispose();
  }

  Widget bothPanels(BuildContext context, BoxConstraints constraints) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: ScopedModelDescendant<AppStateModel>(
          builder: (context, child, model) {
            return (model.blocks.blocks.isNotEmpty || model.blocks.recentProducts.isNotEmpty) ? CustomScrollView(
              controller: _scrollController,
              slivers: [
                CustomSliverAppBar(appBarStyle: model.blocks.settings.appBarStyle, onTapAddress: _onTapAddress),
                for (var i = 0; i < model.blocks.blocks.length; i++)
                  SliverBlock(block: model.blocks.blocks[i]),
                if (model.blocks.recentProducts.length > 0 && model.blocks.settings.homePageProducts)
                  ProductGridPage(products: model.blocks.recentProducts),
                if (model.blocks.recentProducts.length > 0 && model.blocks.settings.homePageProducts)
                  SliverPadding(
                      padding: EdgeInsets.all(0.0),
                      sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            Container(
                                height: 60,
                                child: ScopedModelDescendant<AppStateModel>(
                                    builder: (context, child, model) {
                                      if (model.blocks.recentProducts.length > 0 && model.hasMoreRecentItem == false) {
                                        return Center(
                                          child: Text(
                                            model.blocks.localeText.noMoreProducts,
                                          ),
                                        );
                                      } else {
                                        return Center(child: LoadingIndicator());
                                      }
                                    }))
                          ])))
              ],
            ): CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(child: LoadingIndicator()),
                )),
              ],
            );
          }
      ),
    );
  }

  _onTapAddress() async {
    if(appStateModel.blocks.settings.customLocation) {
      await Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PlaceSelector();
      }));
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PlacePickerHome();
      }));
      setState(() {});
      /*widget.model.getAllStores();*/
      await appStateModel.updateAllBlocks();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: bothPanels,
    );
  }
}


const BorderSide _kDefaultRoundedBorderSide = BorderSide(
  color: CupertinoDynamicColor.withBrightness(
    color: Color(0x33000000),
    darkColor: Color(0x33FFFFFF),
  ),
  width: 0.0,
);
const Border _kDefaultRoundedBorder = Border(
  top: _kDefaultRoundedBorderSide,
  bottom: _kDefaultRoundedBorderSide,
  left: _kDefaultRoundedBorderSide,
  right: _kDefaultRoundedBorderSide,
);

class CustomSliverAppBar extends StatefulWidget {
  final AppBarStyle appBarStyle;
  final Function onTapAddress;
  const CustomSliverAppBar({Key? key, required this.appBarStyle, required this.onTapAddress}) : super(key: key);
  @override
  _CustomSliverAppBarState createState() => _CustomSliverAppBarState();
}

class _CustomSliverAppBarState extends State<CustomSliverAppBar> {

  Color? fillColor;

  String barcode = "";

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<AppStateModel>(
        builder: (context, child, model) {
          return Builder(
              builder: (context) {
                switch (widget.appBarStyle.appBarType) {
                  case 'STYLE1':
                    return SliverAppBar(
                      floating: false,
                      pinned: true,
                      snap: false,
                      stretch: false,
                      titleSpacing: 0,
                      leading: IconButton(
                        icon: DunesIcon(iconString: model.blocks.settings.menuIcon),
                        onPressed: () {
                          z.toggle!();
                        },
                      ), //Container(width: 8, child: HeaderLogo()),
                      title: Padding(
                        padding: widget.appBarStyle.drawer == false && widget.appBarStyle.logo == false ? EdgeInsetsDirectional.only(start: 32.0) : EdgeInsetsDirectional.all(0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(widget.appBarStyle.borderRadius),
                              enableFeedback: false,
                              splashColor: Colors.transparent,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) {
                                  return Search();
                                }));
                              },
                              child: CupertinoTextField(
                                style: TextStyle(
                                  fontFamily: Theme.of(context).textTheme.titleMedium!.fontFamily,
                                ),
                                enabled: false,
                                decoration: BoxDecoration(
                                  color: CupertinoDynamicColor.withBrightness(
                                    color: CupertinoColors.white,
                                    darkColor: CupertinoColors.black,
                                  ),
                                  border: _kDefaultRoundedBorder,
                                  borderRadius: BorderRadius.all(Radius.circular(widget.appBarStyle.borderRadius)),
                                ),
                                prefix: Container(
                                  padding: EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                                  child: DunesIcon(iconString: model.blocks.settings.searchIcon, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : CupertinoColors.placeholderText),
                                ),
                                /*suffix: widget.appBarStyle.barcode ? Container(
                          height: 38,
                          child: IgnorePointer(
                            ignoring: false,
                            child: IconButton(
                                onPressed: () {
                                  _barCodeScan(context);
                                },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                            ),
                          ),
                        ) : Container(),*/
                                placeholder: model.blocks.localeText.search,
                                onChanged: (value) {

                                },
                              ),
                            ),
                            Positioned.directional(
                              textDirection: Directionality.of(context),
                              end: 0,
                              child: widget.appBarStyle.barcode ? IgnorePointer(
                                ignoring: false,
                                child: IconButton(
                                    onPressed: () {
                                      _barCodeScan(context);
                                    },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                                ),
                              ) : Container(),
                            )
                          ],
                        ),
                      ),
                      actions: [
                        for (var i = 0; i < widget.appBarStyle.actions.length; i++)
                          IconButton(onPressed: () {
                            onItemClick(widget.appBarStyle.actions[i], context);
                          }, icon: DunesIcon(iconString: widget.appBarStyle.actions[i].leading, color: Theme.of(context).primaryIconTheme.color)),
                        widget.appBarStyle.cart ? CartIcon() : Container(width: 0),
                        widget.appBarStyle.wishListIcon ? IconButton(onPressed: () {
                          if(model.user.id == 0) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return WishList();
                            }));
                          }
                        }, icon: DunesIcon(iconString: model.blocks.settings.wishListIcon)) : Container(width: 0),
                        widget.appBarStyle.searchIcon ? IconButton(onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return Search();
                          }));
                        }, icon: DunesIcon(iconString: model.blocks.settings.searchIcon)) : Container(width: 0),
                      ],
                    );
                  case 'STYLE2':
                    return SliverAppBar(
                      expandedHeight: 100.0,
                      floating: true,
                      pinned: false,
                      snap: false,
                      stretch: false,
                      leading: IconButton(
                        icon: DunesIcon(iconString: model.blocks.settings.menuIcon),
                        onPressed: () {
                          z.toggle!();
                        },
                      ), //C
                      title: HeaderLogo(),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(46.0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(widget.appBarStyle.borderRadius),
                                enableFeedback: false,
                                splashColor: Colors.transparent,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                                    return Search();
                                  }));
                                },
                                child: CupertinoTextField(
                                  style: TextStyle(
                                    fontFamily: Theme.of(context).textTheme.titleMedium!.fontFamily,
                                  ),
                                  enabled: false,
                                  decoration: BoxDecoration(
                                    color: CupertinoDynamicColor.withBrightness(
                                      color: CupertinoColors.white,
                                      darkColor: CupertinoColors.black,
                                    ),
                                    border: _kDefaultRoundedBorder,
                                    borderRadius: BorderRadius.all(Radius.circular(widget.appBarStyle.borderRadius)),
                                  ),
                                  prefix: Container(
                                    padding: EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                                    child: DunesIcon(iconString: model.blocks.settings.searchIcon, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : CupertinoColors.placeholderText),
                                  ),
                                  /*suffix: widget.appBarStyle.barcode ? Container(
                          height: 38,
                          child: IgnorePointer(
                            ignoring: false,
                            child: IconButton(
                                onPressed: () {
                                  _barCodeScan(context);
                                },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                            ),
                          ),
                        ) : Container(),*/
                                  placeholder: model.blocks.localeText.search,
                                  onChanged: (value) {

                                  },
                                ),
                              ),
                              Positioned.directional(
                                textDirection: Directionality.of(context),
                                end: 0,
                                child: widget.appBarStyle.barcode ? IgnorePointer(
                                  ignoring: false,
                                  child: IconButton(
                                      onPressed: () {
                                        _barCodeScan(context);
                                      },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                                  ),
                                ) : Container(),
                              )
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        for (var i = 0; i < widget.appBarStyle.actions.length; i++)
                          IconButton(onPressed: () {
                            onItemClick(widget.appBarStyle.actions[i], context);
                          }, icon: DunesIcon(iconString: widget.appBarStyle.actions[i].leading/*, color: Theme.of(context).primaryIconTheme.color*/)),
                        widget.appBarStyle.cart ? CartIcon() : Container(width: 0),
                        widget.appBarStyle.wishListIcon ? IconButton(onPressed: () {
                          if(model.user.id == 0) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return WishList();
                            }));
                          }
                        }, icon: DunesIcon(iconString: model.blocks.settings.wishListIcon)) : Container(width: 0),
                        widget.appBarStyle.searchIcon ? IconButton(onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return Search();
                          }));
                        }, icon: DunesIcon(iconString: model.blocks.settings.searchIcon)) : Container(width: 0),
                      ],
                    );
                  case 'STYLE3':
                    return SliverAppBar(
                      expandedHeight: 100.0,
                      floating: false,
                      pinned: true,
                      snap: false,
                      stretch: false,
                      title: HeaderLogo(),
                      leading: IconButton(
                        icon: DunesIcon(iconString: model.blocks.settings.menuIcon),
                        onPressed: () {
                          z.toggle!();
                        },
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(44.0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(widget.appBarStyle.borderRadius),
                                enableFeedback: false,
                                splashColor: Colors.transparent,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                                    return Search();
                                  }));
                                },
                                child: CupertinoTextField(
                                  style: TextStyle(
                                    fontFamily: Theme.of(context).textTheme.titleMedium!.fontFamily,
                                  ),
                                  enabled: false,
                                  decoration: BoxDecoration(
                                    color: CupertinoDynamicColor.withBrightness(
                                      color: CupertinoColors.white,
                                      darkColor: CupertinoColors.black,
                                    ),
                                    border: _kDefaultRoundedBorder,
                                    borderRadius: BorderRadius.all(Radius.circular(widget.appBarStyle.borderRadius)),
                                  ),
                                  prefix: Container(
                                    padding: EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                                    child: DunesIcon(iconString: model.blocks.settings.searchIcon, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : CupertinoColors.placeholderText),
                                  ),
                                  /*suffix: widget.appBarStyle.barcode ? Container(
                          height: 38,
                          child: IgnorePointer(
                            ignoring: false,
                            child: IconButton(
                                onPressed: () {
                                  _barCodeScan(context);
                                },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                            ),
                          ),
                        ) : Container(),*/
                                  placeholder: model.blocks.localeText.search,
                                  onChanged: (value) {

                                  },
                                ),
                              ),
                              Positioned.directional(
                                textDirection: Directionality.of(context),
                                end: 0,
                                child: widget.appBarStyle.barcode ? IgnorePointer(
                                  ignoring: false,
                                  child: IconButton(
                                      onPressed: () {
                                        _barCodeScan(context);
                                      },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                                  ),
                                ) : Container(),
                              )
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        for (var i = 0; i < widget.appBarStyle.actions.length; i++)
                          IconButton(onPressed: () {
                            onItemClick(widget.appBarStyle.actions[i], context);
                          }, icon: DunesIcon(iconString: widget.appBarStyle.actions[i].leading, color: Theme.of(context).primaryIconTheme.color)),
                        widget.appBarStyle.cart ? CartIcon() : Container(width: 0),
                        widget.appBarStyle.wishListIcon ? IconButton(onPressed: () {
                          if(model.user.id == 0) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return WishList();
                            }));
                          }
                        }, icon: DunesIcon(iconString: model.blocks.settings.wishListIcon)) : Container(width: 0),
                        widget.appBarStyle.searchIcon ? IconButton(onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return Search();
                          }));
                        }, icon: DunesIcon(iconString: model.blocks.settings.searchIcon)) : Container(width: 0),
                      ],
                    );
                  case 'STYLE4':
                    return SliverAppBar(
                      expandedHeight: 100.0,
                      floating: true,
                      pinned: true,
                      snap: false,
                      stretch: false,
                      leading: IconButton(
                        icon: DunesIcon(iconString: model.blocks.settings.menuIcon),
                        onPressed: () {
                          z.toggle!();
                        },
                      ),
                      title: HeaderLogo(),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(60.0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(widget.appBarStyle.borderRadius),
                                enableFeedback: false,
                                splashColor: Colors.transparent,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                                    return Search();
                                  }));
                                },
                                child: CupertinoTextField(
                                  style: TextStyle(
                                    fontFamily: Theme.of(context).textTheme.titleMedium!.fontFamily,
                                  ),
                                  enabled: false,
                                  decoration: BoxDecoration(
                                    color: CupertinoDynamicColor.withBrightness(
                                      color: CupertinoColors.white,
                                      darkColor: CupertinoColors.black,
                                    ),
                                    border: _kDefaultRoundedBorder,
                                    borderRadius: BorderRadius.all(Radius.circular(widget.appBarStyle.borderRadius)),
                                  ),
                                  prefix: Container(
                                    padding: EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                                    child: DunesIcon(iconString: model.blocks.settings.searchIcon, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : CupertinoColors.placeholderText),
                                  ),
                                  /*suffix: widget.appBarStyle.barcode ? Container(
                          height: 38,
                          child: IgnorePointer(
                            ignoring: false,
                            child: IconButton(
                                onPressed: () {
                                  _barCodeScan(context);
                                },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                            ),
                          ),
                        ) : Container(),*/
                                  placeholder: model.blocks.localeText.search,
                                  onChanged: (value) {

                                  },
                                ),
                              ),
                              Positioned.directional(
                                textDirection: Directionality.of(context),
                                end: 0,
                                child: widget.appBarStyle.barcode ? IgnorePointer(
                                  ignoring: false,
                                  child: IconButton(
                                      onPressed: () {
                                        _barCodeScan(context);
                                      },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                                  ),
                                ) : Container(),
                              )
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        for (var i = 0; i < widget.appBarStyle.actions.length; i++)
                          IconButton(onPressed: () {
                            onItemClick(widget.appBarStyle.actions[i], context);
                          }, icon: DunesIcon(iconString: widget.appBarStyle.actions[i].leading, color: Theme.of(context).primaryIconTheme.color)),
                        widget.appBarStyle.cart ? CartIcon() : Container(width: 0),
                        widget.appBarStyle.wishListIcon ? IconButton(onPressed: () {
                          if(model.user.id == 0) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return WishList();
                            }));
                          }
                        }, icon: DunesIcon(iconString: model.blocks.settings.wishListIcon)) : Container(width: 0),
                        widget.appBarStyle.searchIcon ? IconButton(onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return Search();
                          }));
                        }, icon: DunesIcon(iconString: model.blocks.settings.searchIcon)) : Container(width: 0),
                      ],
                    );
                  case 'STYLE5':
                    return SliverAppBar(
                      centerTitle: false,
                      //automaticallyImplyLeading: false,
                      titleSpacing: 0,
                      leading: IconButton(
                        icon: DunesIcon(iconString: model.blocks.settings.menuIcon),
                        onPressed: () {
                          z.toggle!();
                        },
                      ),
                      title: Padding(
                        padding: widget.appBarStyle.barcode || widget.appBarStyle.drawer ? EdgeInsetsDirectional.only(start: 0.0) : EdgeInsetsDirectional.only(start: 16.0),
                        child: widget.appBarStyle.logo ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                          child: HeaderLogo(),
                        ) : buildHomeTitle(context),
                      ),
                      expandedHeight: !widget.appBarStyle.location ? null : 110,
                      flexibleSpace: widget.appBarStyle.location ? FlexibleSpaceBar(
                        background: Container(
                          child: Stack(
                            children: <Widget>[
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  color: Theme.of(context).primaryColorLight.withOpacity(0.1),
                                  height: 50,
                                  width: MediaQuery.of(context).size.width,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
                                    child: InkWell(
                                      onTap: () async {
                                        widget.onTapAddress();
                                      },
                                      child: Row(
                                        children: [
                                          Icon(FontAwesomeIcons.mapMarkerAlt),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Expanded(
                                              //width: MediaQuery.of(context).size.width - 110,
                                              child: Builder(
                                                  builder: (context) {
                                                    if (model.customerLocation['address'] != null)
                                                      return Text(model.customerLocation['address'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                                          fontSize: 14
                                                      ));
                                                    else
                                                      return Text(model.blocks.localeText.selectLocation, style: TextStyle(
                                                          fontSize: 14
                                                      ));
                                                  }
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ) : null,
                      actions: [
                        for (var i = 0; i < widget.appBarStyle.actions.length; i++)
                          IconButton(onPressed: () {
                            onItemClick(widget.appBarStyle.actions[i], context);
                          }, icon: DunesIcon(iconString: widget.appBarStyle.actions[i].leading)),
                        widget.appBarStyle.cart ? CartIcon() : Container(width: 0),
                        widget.appBarStyle.searchIcon ? IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return Search();
                            }));
                          },
                          icon: Icon(FlutterRemix.search_2_line),) : Container(width: 0),
                        (widget.appBarStyle.cart || widget.appBarStyle.searchIcon) ? Container() : Container(width: 16)
                      ],
                    );
                  case 'STYLE6':
                    return SliverAppBar(
                      pinned: true,
                      floating: true,
                      snap: false,
                      titleSpacing: 0,
                      centerTitle: false,
                      leading: IconButton(
                        icon: DunesIcon(iconString: model.blocks.settings.menuIcon),
                        onPressed: () {
                          z.toggle!();
                        },
                      ),
                      expandedHeight: widget.appBarStyle.searchBar ? 110 : 0,
                      title: widget.appBarStyle.logo ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: HeaderLogo(),
                      ) : InkWell(
                        onTap: () async {
                          widget.onTapAddress();
                        },
                        child: model.blocks.settings.geoLocation ? Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8.0),
                          child: Row(
                            children: [
                              Icon(FontAwesomeIcons.mapMarkerAlt),
                              SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                //width: MediaQuery.of(context).size.width - 110,
                                  child: model.customerLocation['address'] != null ? Text(model.customerLocation['address'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                      fontSize: 14
                                  )) : Text(model.blocks.localeText.selectLocation, style: TextStyle(
                                      fontSize: 14
                                  ))
                              ),
                            ],
                          ),
                        ) : Container(),
                      ),
                      flexibleSpace: widget.appBarStyle.searchBar ? FlexibleSpaceBar(
                        background: Column(
                          children: <Widget>[
                            SizedBox(height: Platform.isIOS ? 96.0 : 80.0),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 8.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(4),
                                enableFeedback: false,
                                splashColor: Colors.transparent,
                                onTap: () {

                                },
                                child: buildHomeTitle(context),
                              ),
                            ),
                          ],
                        ),
                      ) : null,
                      actions: [
                        for (var i = 0; i < widget.appBarStyle.actions.length; i++)
                          IconButton(onPressed: () {
                            onItemClick(widget.appBarStyle.actions[i], context);
                          }, icon: DunesIcon(iconString: widget.appBarStyle.actions[i].leading)),
                        widget.appBarStyle.cart ? CartIcon() : Container(width: 0),
                        widget.appBarStyle.searchIcon ? IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return Search();
                            }));
                          },
                          icon: Icon(FlutterRemix.search_2_line),) : Container(width: 0),
                        (widget.appBarStyle.cart || widget.appBarStyle.searchIcon) ? Container() : Container(width: 16)
                      ],
                    );
                  case 'STYLE7':
                    return SliverAppBar(
                      //automaticallyImplyLeading: false,
                      pinned: true,
                      floating: true,
                      snap: false,
                      titleSpacing: 0,
                      leading: IconButton(
                        icon: DunesIcon(iconString: model.blocks.settings.menuIcon),
                        onPressed: () {
                          z.toggle!();
                        },
                      ),
                      centerTitle: false,
                      expandedHeight: widget.appBarStyle.searchBar ? 110 : 0,
                      title: widget.appBarStyle.logo ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: HeaderLogo(),
                      ) : InkWell(
                        onTap: () async {
                          widget.onTapAddress();
                        },
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8.0),
                          child: Row(
                            children: [
                              Icon(FontAwesomeIcons.mapMarkerAlt),
                              SizedBox(
                                width: 8,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width - 155,
                                child: Builder(
                                    builder: (context) {
                                      if (model.customerLocation['address'] != null)
                                        return Text(model.customerLocation['address'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                            fontSize: 14
                                        ));
                                      else
                                        return Text(model.blocks.localeText.selectLocation, style: TextStyle(
                                            fontSize: 14
                                        ));
                                    }
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      flexibleSpace: widget.appBarStyle.searchBar ? FlexibleSpaceBar(
                        background: Column(
                          children: <Widget>[
                            SizedBox(height: Platform.isIOS ? 96.0 : 80.0),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 8.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(widget.appBarStyle.borderRadius),
                                enableFeedback: false,
                                splashColor: Colors.transparent,
                                onTap: () {

                                },
                                child: buildCupertinoSearchFiled(context),
                              ),
                            ),
                          ],
                        ),
                      ) : null,
                      actions: [
                        for (var i = 0; i < widget.appBarStyle.actions.length; i++)
                          IconButton(onPressed: () {
                            onItemClick(widget.appBarStyle.actions[i], context);
                          }, icon: DunesIcon(iconString: widget.appBarStyle.actions[i].leading)),
                        widget.appBarStyle.cart ? CartIcon() : Container(width: 0),
                        widget.appBarStyle.searchIcon ?
                        IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return Search();
                            }));
                          },
                          icon: Icon(FlutterRemix.search_2_line),) : Container(width: 0),
                        (widget.appBarStyle.cart || widget.appBarStyle.searchIcon) ? Container() : Container(width: 16)
                      ],
                    );
                  case 'STYLE8':
                    return SliverAppBar(
                      centerTitle: false,
                      pinned: true,
                      floating: true,
                      snap: false,
                      leading: IconButton(
                        icon: DunesIcon(iconString: model.blocks.settings.menuIcon),
                        onPressed: () {
                          z.toggle!();
                        },
                      ),
                      titleSpacing: 0,
                      title: Padding(
                        padding: widget.appBarStyle.barcode || widget.appBarStyle.drawer ? EdgeInsetsDirectional.only(start: 0.0) : EdgeInsetsDirectional.only(start: 16.0),
                        child: widget.appBarStyle.logo ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                          child: HeaderLogo(),
                        ) : InkWell(
                          borderRadius: BorderRadius.circular(widget.appBarStyle.borderRadius),
                          enableFeedback: false,
                          splashColor: Colors.transparent,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return Search();
                            }));
                          },
                          child: InkWell(
                            borderRadius: BorderRadius.circular(0),
                            enableFeedback: false,
                            splashColor: Colors.transparent,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) {
                                return Search();
                              }));
                            },
                            child: CupertinoTextField(
                              style: TextStyle(
                                fontFamily: Theme.of(context).textTheme.titleMedium!.fontFamily,
                              ),
                              keyboardType: TextInputType.text,
                              placeholder: model.blocks.localeText.searchProducts,
                              placeholderStyle: Theme.of(context).textTheme.bodyText2!.copyWith(
                                  color: Theme.of(context).textTheme.caption!.color
                              ),
                              enabled: false,
                              prefix: Padding(
                                padding: const EdgeInsets.fromLTRB(9.0, 6.0, 9.0, 6.0),
                                child: DunesIcon(iconString: model.blocks.settings.searchIcon, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : CupertinoColors.placeholderText),
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      expandedHeight: widget.appBarStyle.location ? 110 : null,
                      flexibleSpace: widget.appBarStyle.location ? FlexibleSpaceBar(
                        background: Container(
                          child: Stack(
                            children: <Widget>[
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  color: Theme.of(context).primaryColorLight,
                                  height: 50,
                                  width: MediaQuery.of(context).size.width,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
                                    child: InkWell(
                                      onTap: () async {
                                        widget.onTapAddress();
                                      },
                                      child: Row(
                                        children: [
                                          Icon(FontAwesomeIcons.mapMarkerAlt),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Expanded(
                                              //width: MediaQuery.of(context).size.width - 110,
                                              child: Builder(
                                                  builder: (context) {
                                                    if (model.customerLocation['address'] != null)
                                                      return Text(model.customerLocation['address'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                                          fontSize: 14
                                                      ));
                                                    else
                                                      return Text(model.blocks.localeText.selectLocation, style: TextStyle(
                                                          fontSize: 14
                                                      ));
                                                  }
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ) : null,
                      actions: [
                        for (var i = 0; i < widget.appBarStyle.actions.length; i++)
                          IconButton(onPressed: () {
                            onItemClick(widget.appBarStyle.actions[i], context);
                          }, icon: DunesIcon(iconString: widget.appBarStyle.actions[i].leading)),
                        widget.appBarStyle.cart ?
                        CartIcon() : Container(width: 0),widget.appBarStyle.searchIcon ? IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return Search();
                            }));
                          },
                          icon: Icon(FlutterRemix.search_2_line),) : Container(width: 0),
                        (widget.appBarStyle.cart || widget.appBarStyle.searchIcon) ? Container() : Container(width: 16)
                      ],
                    );
                  case 'STYLE9':
                    return SliverAppBar(
                      centerTitle: false,
                      //automaticallyImplyLeading: false,
                      titleSpacing: 0,
                      leading: IconButton(
                        icon: DunesIcon(iconString: model.blocks.settings.menuIcon),
                        onPressed: () {
                          z.toggle!();
                        },
                      ),
                      title: Padding(
                        padding: widget.appBarStyle.barcode || widget.appBarStyle.drawer ? EdgeInsetsDirectional.only(start: 0.0) : EdgeInsetsDirectional.only(start: 16.0),
                        child: widget.appBarStyle.logo ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                          child: HeaderLogo(),
                        ) : InkWell(
                          borderRadius: BorderRadius.circular(widget.appBarStyle.borderRadius),
                          enableFeedback: false,
                          splashColor: Colors.transparent,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return Search();
                            }));
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(4.0),
                                enableFeedback: false,
                                splashColor: Colors.transparent,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                                    return Search();
                                  }));
                                },
                                child: CupertinoTextField(
                                  style: TextStyle(
                                    fontFamily: Theme.of(context).textTheme.titleMedium!.fontFamily,
                                  ),
                                  keyboardType: TextInputType.text,
                                  placeholder: model.blocks.localeText.searchProducts,
                                  placeholderStyle: Theme.of(context).textTheme.bodyText2!.copyWith(
                                      color: Theme.of(context).textTheme.caption!.color
                                  ),
                                  enabled: false,
                                  prefix: Padding(
                                    padding: const EdgeInsets.fromLTRB(9.0, 6.0, 9.0, 6.0),
                                    child: DunesIcon(iconString: model.blocks.settings.searchIcon, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : CupertinoColors.placeholderText),
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                              ),
                              Positioned.directional(
                                textDirection: Directionality.of(context),
                                end: 0,
                                child: widget.appBarStyle.barcode ? IgnorePointer(
                                  ignoring: false,
                                  child: IconButton(
                                      onPressed: () {
                                        _barCodeScan(context);
                                      },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                                  ),
                                ) : Container(),
                              )
                            ],
                          ),
                        ),
                      ),
                      expandedHeight: widget.appBarStyle.location ? 110 : null,
                      flexibleSpace: widget.appBarStyle.location ? FlexibleSpaceBar(
                        background: Container(
                          child: Stack(
                            children: <Widget>[
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  color: Theme.of(context).primaryColorLight,
                                  height: 50,
                                  width: MediaQuery.of(context).size.width,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
                                    child: InkWell(
                                      onTap: () async {
                                        widget.onTapAddress();
                                      },
                                      child: Row(
                                        children: [
                                          Icon(FontAwesomeIcons.mapMarkerAlt),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Expanded(
                                              //width: MediaQuery.of(context).size.width - 110,
                                              child: Builder(
                                                  builder: (context) {
                                                    if (model.customerLocation['address'] != null)
                                                      return Text(model.customerLocation['address'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                                          fontSize: 14
                                                      ));
                                                    else
                                                      return Text(model.blocks.localeText.selectLocation, style: TextStyle(
                                                          fontSize: 14
                                                      ));
                                                  }
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ) : null,
                      actions: [
                        for (var i = 0; i < widget.appBarStyle.actions.length; i++)
                          IconButton(onPressed: () {
                            onItemClick(widget.appBarStyle.actions[i], context);
                          }, icon: DunesIcon(iconString: widget.appBarStyle.actions[i].leading)),
                        widget.appBarStyle.cart ? CartIcon() : Container(width: 0),
                        widget.appBarStyle.searchIcon ? IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return Search();
                            }));
                          },
                          icon: Icon(FlutterRemix.search_2_line),) : Container(width: 0),
                        (widget.appBarStyle.cart || widget.appBarStyle.searchIcon) ? Container() : Container(width: 16)
                      ],
                    );
                  default:
                    return SliverAppBar(
                      floating: false,
                      pinned: true,
                      snap: false,
                      stretch: false,
                      titleSpacing: 0,
                      leading: IconButton(
                        icon: DunesIcon(iconString: model.blocks.settings.menuIcon),
                        onPressed: () {
                          z.toggle!();
                        },
                      ), //Container(width: 8, child: HeaderLogo()),
                      title: Padding(
                        padding: widget.appBarStyle.drawer == false && widget.appBarStyle.logo == false ? EdgeInsetsDirectional.only(start: 32.0) : EdgeInsetsDirectional.all(0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(widget.appBarStyle.borderRadius),
                              enableFeedback: false,
                              splashColor: Colors.transparent,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) {
                                  return Search();
                                }));
                              },
                              child: CupertinoTextField(
                                style: TextStyle(
                                  fontFamily: Theme.of(context).textTheme.titleMedium!.fontFamily,
                                ),
                                enabled: false,
                                decoration: BoxDecoration(
                                  color: CupertinoDynamicColor.withBrightness(
                                    color: CupertinoColors.white,
                                    darkColor: CupertinoColors.black,
                                  ),
                                  border: _kDefaultRoundedBorder,
                                  borderRadius: BorderRadius.all(Radius.circular(widget.appBarStyle.borderRadius)),
                                ),
                                prefix: Container(
                                  padding: EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                                  child: DunesIcon(iconString: model.blocks.settings.searchIcon, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : CupertinoColors.placeholderText),
                                ),
                                /*suffix: widget.appBarStyle.barcode ? Container(
                          height: 38,
                          child: IgnorePointer(
                            ignoring: false,
                            child: IconButton(
                                onPressed: () {
                                  _barCodeScan(context);
                                },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                            ),
                          ),
                        ) : Container(),*/
                                placeholder: model.blocks.localeText.search,
                                onChanged: (value) {

                                },
                              ),
                            ),
                            Positioned.directional(
                              textDirection: Directionality.of(context),
                              end: 0,
                              child: widget.appBarStyle.barcode ? IgnorePointer(
                                ignoring: false,
                                child: IconButton(
                                    onPressed: () {
                                      _barCodeScan(context);
                                    },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                                ),
                              ) : Container(),
                            )
                          ],
                        ),
                      ),
                      actions: [
                        for (var i = 0; i < widget.appBarStyle.actions.length; i++)
                          IconButton(onPressed: () {
                            onItemClick(widget.appBarStyle.actions[i], context);
                          }, icon: DunesIcon(iconString: widget.appBarStyle.actions[i].leading, color: Theme.of(context).primaryIconTheme.color)),
                        widget.appBarStyle.cart ? CartIcon() : Container(width: 0),
                        widget.appBarStyle.wishListIcon ? IconButton(onPressed: () {
                          if(model.user.id == 0) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return WishList();
                            }));
                          }
                        }, icon: DunesIcon(iconString: model.blocks.settings.wishListIcon)) : Container(width: 0),
                        widget.appBarStyle.searchIcon ? IconButton(onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return Search();
                          }));
                        }, icon: DunesIcon(iconString: model.blocks.settings.searchIcon)) : Container(width: 0),
                      ],
                    );
                }
              }
          );
        }
    );
  }

  Widget buildCupertinoSearchFiled(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(widget.appBarStyle.borderRadius),
          enableFeedback: false,
          splashColor: Colors.transparent,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return Search();
            }));
          },
          child: CupertinoTextField(
            style: TextStyle(
              fontFamily: Theme.of(context).textTheme.titleMedium!.fontFamily,
            ),
            keyboardType: TextInputType.text,
            placeholder: AppStateModel().blocks.localeText.searchProducts,
            placeholderStyle: Theme.of(context).textTheme.bodyText2!.copyWith(
                color: Theme.of(context).textTheme.caption!.color
            ),
            enabled: false,
            prefix: Padding(
              padding: const EdgeInsets.fromLTRB(9.0, 6.0, 9.0, 6.0),
              child: DunesIcon(iconString: AppStateModel().blocks.settings.searchIcon, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : CupertinoColors.placeholderText),
            ),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.withBrightness(
                color: CupertinoColors.white,
                darkColor: CupertinoColors.black,
              ),
              border: _kDefaultRoundedBorder,
              borderRadius: BorderRadius.all(Radius.circular(widget.appBarStyle.borderRadius)),
            ),
          ),
        ),
        Positioned.directional(
          textDirection: Directionality.of(context),
          end: 0,
          child: widget.appBarStyle.barcode ? IgnorePointer(
            ignoring: false,
            child: IconButton(
                onPressed: () {
                  _barCodeScan(context);
                },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
            ),
          ) : Container(),
        )
      ],
    );
  }

  Widget buildHomeTitle(BuildContext context) {

    final border = OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(widget.appBarStyle.borderRadius)),
        borderSide: BorderSide(color: Colors.transparent));

    if(Theme.of(context).appBarTheme.backgroundColor != null) {
      fillColor = Theme.of(context).appBarTheme.backgroundColor.toString().substring(Theme.of(context).appBarTheme.backgroundColor.toString().length - 7) == 'ffffff)' ? null : Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white;
    } else fillColor = Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.black12;

    return Container(
      height: 40,
      width: MediaQuery.of(context).size.width,
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.appBarStyle.borderRadius),
        enableFeedback: false,
        splashColor: Colors.transparent,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Search();
          }));
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            TextField(
              showCursor: false,
              enabled: false,
              decoration: InputDecoration(
                hintText: AppStateModel().blocks.localeText.searchProducts,
                hintStyle: TextStyle(
                  fontSize: 16,
                ),
                fillColor: fillColor,
                filled: true,
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                errorBorder: border,
                focusedErrorBorder: border,
                disabledBorder: border,
                contentPadding: EdgeInsets.all(4),
                prefixIcon: Icon(
                  FlutterRemix.search_2_line,
                ),
              ),
            ),
            Positioned.directional(
              textDirection:Directionality.of(context),
              end: 0,
              child: widget.appBarStyle.barcode ? IgnorePointer(
                ignoring: false,
                child: IconButton(
                    onPressed: () {
                      _barCodeScan(context);
                    },icon: Icon(CupertinoIcons.barcode_viewfinder, color: Theme.of(context).disabledColor,)
                ),
              ) : Container(),
            )
          ],
        ),
      ),
    );
  }

  _barCodeScan(BuildContext context) async {
    try {
      ScanResult result = await BarcodeScanner.scan();
      if(result.type == ResultType.Barcode) {
        showDialog(builder: (context) => FindBarCodeProduct(result: result.rawContent, context: context), context: context);
      } else {
        setState(() {
          this.barcode = 'The user did not grant the camera permission!';
        });
      }

    } on PlatformException catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    } on FormatException{
      setState(() => this.barcode = 'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
  }

  _onPressCartIcon(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => CartPage(),
          fullscreenDialog: true,
        ));
  }
}

class MyDrawer extends StatefulWidget {
  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<AppStateModel>(
        builder: (context, child, model) {
          return Drawer(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : model.blocks.settings.menuTheme.light.canvasColor,
              elevation: 0,
              child: CustomScrollView(slivers: _buildList(model)));
        });
  }

  _buildList(AppStateModel model) {
    List<Widget> list = [];

    bool isDark = Theme.of(context).brightness == Brightness.dark;
    //Color iconColor = isDark ? Theme.of(context).iconTheme.color! : model.blocks.settings.menuTheme.light.hintColor;
    Color headerColor = model.blocks.settings.menuTheme.light.disabledColor;

    Color foreGroundColor = model.blocks.settings.menuTheme.light.canvasColor.isDark ? Colors.white : Colors.black;

    list.add(SliverAppBar(
        automaticallyImplyLeading: false,
        pinned: true,
        floating: true,
        expandedHeight: model.blocks.settings.menuBackgroundImage.isNotEmpty ? 80.0 : 0,
        stretch: false,
        elevation: 0,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : model.blocks.settings.menuTheme.light.canvasColor,
        title: model.blocks.settings.menuBackgroundImage.isEmpty ? Text(model.blocks.localeText.account) : null,
        flexibleSpace: model.blocks.settings.menuBackgroundImage.isNotEmpty
            ? FlexibleSpaceBar(
          stretchModes: [StretchMode.zoomBackground],
          background: CachedNetworkImage(
            imageUrl: model.blocks.settings.menuBackgroundImage,
            placeholder: (context, url) => Container(color: Colors.grey.withOpacity(0.2),),
            errorWidget: (context, url, error) => Container(color: Colors.grey.withOpacity(0.2),),
            fit: BoxFit.cover,
          ),
        ) : null
    )
    );

    model.blocks.settings.menuGroup.forEach((menuGroup) {
      if (menuGroup.showTitle) {
        list.add(SliverToBoxAdapter(
          child: ListTile(
            subtitle: Text(menuGroup.title,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: foreGroundColor
                )),
          ),
        ));
      } else
        list.add(SliverToBoxAdapter(child: SizedBox(height: 16)));

      if (menuGroup.type == 'categories') {
        List<Category> categories = model.blocks.categories
            .where((element) => element.parent == 0)
            .toList();
        list.add(SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) => Column(
              children: [
                ListTile(
                  onTap: () {
                    onCategoryClick(categories[index], context);
                    /*var filter = new Map<String, dynamic>();
                    filter['id'] = categories[index].id.toString();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProductsWidget(
                                filter: filter, name: categories[index].name)));*/
                  },
                  leading: categories[index].image.isNotEmpty ? Container(
                    constraints: BoxConstraints(
                        maxHeight: 30,
                        maxWidth: 30,
                        minHeight: 30,
                        minWidth: 30),
                    child: Image.network(
                      categories[index].image,
                      fit: BoxFit.cover,
                    ),
                  ) : null,
                  trailing: Icon(Icons.arrow_right_rounded/*, color: iconColor*/),
                  title: Text(parseHtmlString(categories[index].name), style: TextStyle(color: foreGroundColor),),
                ),
                
              ],
            ),
            childCount: categories.length,
          ),
        ));
      } else if (menuGroup.type == 'expandableCategories') {
        list.add(SliverToBoxAdapter(
            child:
            ExpandableCategoryList(categories: model.blocks.categories)));
      } else if (menuGroup.type == 'postCategories') {
        List<Category> categories = model.blocks.categories
            .where((element) => element.parent == 0)
            .toList();
        list.add(SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) => Column(
              children: [
                ListTile(
                  onTap: () {
                    onCategoryClick(categories[index], context);
                    //Navigate to Post Category
                    /*var filter = new Map<String, dynamic>();
                    filter['id'] = categories[index].id.toString();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProductsWidget(
                                filter: filter, name: categories[index].name)));*/
                  },
                  leading: Container(
                    constraints: BoxConstraints(
                        maxHeight: 30,
                        maxWidth: 30,
                        minHeight: 30,
                        minWidth: 30),
                    child: Image.network(
                      categories[index].image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_right_rounded/*, color: iconColor*/),
                  title: Text(parseHtmlString(categories[index].name), style: TextStyle(color: foreGroundColor),),
                ),
                
              ],
            ),
            childCount: categories.length,
          ),
        ));
      } else {
        list.add(SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              if (['vendorProducts', 'vendorOrders', 'vendorWebView'].contains(menuGroup.menuItems[index].linkType) &&
                  !model.isVendor.contains(model.user.role)) {
                return Container();
              } else if (menuGroup.menuItems[index].linkType == 'login' &&
                  model.user.id > 0) {
                return Container();
              } else if (menuGroup.menuItems[index].linkType == 'logout' &&
                  model.user.id == 0) {
                return Container();
              } else
                return Column(
                  children: [
                    ListTile(
                      onTap: () {
                        onItemClick(menuGroup.menuItems[index], context);
                      },
                      leading: menuGroup.menuItems[index].leading.isNotEmpty
                          ? DunesIcon(iconString: menuGroup.menuItems[index].leading, color: foreGroundColor.withOpacity(0.6))
                          : null,
                      trailing: menuGroup.menuItems[index].trailing.isNotEmpty
                          ? DunesIcon(iconString: menuGroup.menuItems[index].trailing, color: foreGroundColor.withOpacity(0.6))
                          : null,
                      title: Text(menuGroup.menuItems[index].title, style: TextStyle(color: foreGroundColor),),
                      subtitle: menuGroup.menuItems[index].description.isNotEmpty ? Text(menuGroup.menuItems[index].description) : null,
                    ),
                    
                  ],
                );
            },
            childCount: menuGroup.menuItems.length,
          ),
        ));
      }
    });

    if (model.blocks.settings.menuSocialLink) {
      list.add(SliverToBoxAdapter(
        child: Container(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
          height: 80,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (model.blocks.settings.socialLink.facebook.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                    icon: Icon(FontAwesomeIcons.facebookF),
                    iconSize: 15,
                    color: Color(0xff4267B2),
                    onPressed: () {
                      launchUrl(Uri.parse(model.blocks.settings.socialLink.facebook), mode: LaunchMode.externalApplication);
                    },
                  ),
                if (model.blocks.settings.socialLink.twitter.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                    icon: Icon(FontAwesomeIcons.twitter),
                    iconSize: 15,
                    color: Color(0xff1DA1F2),
                    onPressed: () {
                      launchUrl(Uri.parse(model.blocks.settings.socialLink.twitter), mode: LaunchMode.externalApplication);
                    },
                  ),
                if (model.blocks.settings.socialLink.linkedIn.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                    icon: Icon(FontAwesomeIcons.linkedinIn),
                    iconSize: 15,
                    color: Color(0xff0e76a8),
                    onPressed: () {
                      launchUrl(Uri.parse(model.blocks.settings.socialLink.linkedIn), mode: LaunchMode.externalApplication);
                    },
                  ),
                if (model.blocks.settings.socialLink.instagram.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                    icon: Icon(FontAwesomeIcons.instagram),
                    iconSize: 15,
                    color: Color(0xfffb3958),
                    onPressed: () {
                      launchUrl(Uri.parse(model.blocks.settings.socialLink.instagram), mode: LaunchMode.externalApplication);
                    },
                  ),
                if (model.blocks.settings.socialLink.whatsapp.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                    icon: Icon(FontAwesomeIcons.whatsapp),
                    iconSize: 15,
                    color: Color(0xff128C7E),
                    onPressed: () {
                      launchUrl(Uri.parse(model.blocks.settings.socialLink.whatsapp), mode: LaunchMode.externalApplication);
                    },
                  )
              ],
            ),
          ),
        ),
      ));
    } else {
      list.add(SliverToBoxAdapter(
        child: SizedBox(height: 16),
      ));
    }

    if (model.blocks.settings.socialLink.bottomText.isNotEmpty)
      list.add(SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: TextButton(
              child: Text(model.blocks.settings.socialLink.bottomText, textAlign: TextAlign.center, style: TextStyle(color: foreGroundColor.withOpacity(0.6)),),
              onPressed: () async {
                if (model.blocks.settings.socialLink.bottomText.contains('@') &&
                    model.blocks.settings.socialLink.bottomText.contains('.'))
                  launch(
                      'mailto:' + model.blocks.settings.socialLink.bottomText);
                else {
                  await canLaunch(model.blocks.settings.socialLink.bottomText)
                      ? await launch(
                      model.blocks.settings.socialLink.bottomText)
                      : throw 'Could not launch ${model.blocks.settings.socialLink.bottomText}';
                }
              },
            ),
          ),
        ),
      ));

    list.add(SliverToBoxAdapter(
      child: SizedBox(height: 40),
    ));

    return list;
  }
}


class ZooDrawerApp extends StatefulWidget {
  final appStateModel = AppStateModel();
  ZooDrawerApp({Key? key}) : super(key: key);
  @override
  _ZooDrawerAppState createState() => _ZooDrawerAppState();
}

class _ZooDrawerAppState extends State<ZooDrawerApp> with TickerProviderStateMixin {

  //int _currentIndex = 0;
  List<Category> mainCategories = [];
  List<Widget> _children = [];
  bool enableStoreTab = false;
  late int bottomItemsLength;

  @override
  void initState() {
    configureFcm();
    this.initDynamicLinks();
    enableStoreTab = widget.appStateModel.blocks.settings.storeTab;

    bottomItemsLength = widget.appStateModel.blocks.settings.bottomNavigationBar.items.length;

    if(bottomItemsLength < 2) {
      if(widget.appStateModel.blocks.settings.pageLayout.home == 'layout2') {
        _children.add(Body());
      } else if(widget.appStateModel.blocks.settings.pageLayout.home == 'layout3') {
        _children.add(Body());
      } else if(widget.appStateModel.blocks.settings.pageLayout.home == 'layout1') {
        _children.add(Body());
      } else {
        _children.add(Body());
      }
    } else {
      print(widget.appStateModel.blocks.settings.pageLayout.home);
      widget.appStateModel.blocks.settings.bottomNavigationBar.items.forEach((element) {
        if(element.link == 'home') {
          if(widget.appStateModel.blocks.settings.pageLayout.home == 'layout2') {
            _children.add(Body());
          } else if(widget.appStateModel.blocks.settings.pageLayout.home == 'layout3') {
            _children.add(Body());
          } else if(widget.appStateModel.blocks.settings.pageLayout.home == 'layout1') {
            _children.add(Body());
          } else {
            _children.add(Body());
          }
        } else if(element.link == 'category') {
          _children.add(Categories());
        } else if(element.link == 'store') {
          _children.add(StoreListPage());
        } else if(element.link == 'orders') {
          _children.add(OrderList());
        } else if(element.link == 'search') {
          _children.add(Search());
        } /*else if(element.link == 'bookings') {
          _children.add(BookingsPage());
        } */else if(element.link == 'template') {
          String id = element.linkId != null ? element.linkId! : '0';
          _children.add(BlockPage(child: Child(linkType: 'template', linkId: id, title: element.title)));
        } else if(element.link == 'wishlist') {
          _children.add(WishList());
        } else if(element.link == 'cart') {
          _children.add(CartPage());
        } else if(element.link == 'account') {
          _children.add(Account());
        } else if(element.link == 'webView') {
          String id = element.linkId != null ? element.linkId! : '0';
          _children.add(WebViewPage(url: id));
        } else if(element.link == 'pageWebView') {
          _children.add(WebViewPage(url: element.linkId!));
        } else if(element.link == 'post') {
          var child = Child(linkId: element.linkId!, linkType: 'post');
          _children.add(WPPostPage(child: child));
        } else if(element.link == 'page') {
          var child = Child(linkId: element.linkId!, linkType: 'page');
          _children.add(WPPostPage(child: child));
        } else if(element.link == 'contactForm7') {
          Category category = new Category(id: int.parse(element.linkId!), name: element.title);
          _children.add(ContactForm7(category: category));
        } else {
          _children.add(Categories());
        }
      });
    }

    super.initState();
  }

  Future<void> onChangePageIndex(int index) async {
    if(widget.appStateModel.blocks.settings.bottomNavigationBar.items.length > index) {
      if(['wishlist', 'orders', 'booking'].contains(widget.appStateModel.blocks.settings.bottomNavigationBar.items[index].link) && widget.appStateModel.user.id == 0) {
        await Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (context) => Login()));
        setState(() {});
      } else {
        widget.appStateModel.currentPageIndex = index;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    //Uncomment only when testing without location
    /*return Scaffold(
      drawerDragStartBehavior: DragStartBehavior.start,
      floatingActionButton: ScopedModelDescendant<AppStateModel>(
          builder: (context, child, model) {
            if (model.blocks.settings.homePageChat == true && widget.appStateModel.currentPageIndex == 0) {
              return FloatingActionButton(
                onPressed: () =>
                    _openWhatsApp(model.blocks.settings.phoneNumber.toString()),
                tooltip: 'Chat',
                child: Icon(Icons.chat_bubble),
              );
            } else {
              return Container();
            }
          }),
      body: _children[widget.appStateModel.currentPageIndex],
      bottomNavigationBar: buildBottomNavigationBar(context),
    );*/

    if (widget.appStateModel.blocks.settings.geoLocation && widget.appStateModel.blocks.settings.customLocation) {
      return ScopedModelDescendant<AppStateModel>(
          builder: (context, child, model) {
            if (model.customerLocation['name'] == null && model.blocks.settings.locations.length > 0) {
              return Scaffold(body: PlaceSelector() // create login with no pop()
              );
            } else {
              return Scaffold(
                drawerDragStartBehavior: DragStartBehavior.start,
                floatingActionButton: ScopedModelDescendant<AppStateModel>(
                    builder: (context, child, model) {
                      if (model.blocks.settings.homePageChat &&
                          widget.appStateModel.currentPageIndex == 0) {
                        return AccountFloatingButton(page: 'home');
                      } else {
                        return Container();
                      }
                    }),
                body: _children[widget.appStateModel.currentPageIndex],
                bottomNavigationBar: buildBottomNavigationBar(context),
              );
            }
          }
      );
    }

    else if (widget.appStateModel.blocks.settings.geoLocation && widget.appStateModel.blocks.settings.googleMapLocation) {
      return ScopedModelDescendant<AppStateModel>(
          builder: (context, child, model) {
            if (model.loading) {
              return Scaffold(
                body: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle.light,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      width: MediaQuery.of(context).size.width - 32,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            } else if (model.customerLocation['latitude'] == null) {
              return Scaffold(body: PlacePickerHome() // create login with no pop()
              );
            } else if (model.blocks.stores.length != 0) {
              return Scaffold(
                drawerDragStartBehavior: DragStartBehavior.start,
                floatingActionButton: ScopedModelDescendant<AppStateModel>(
                    builder: (context, child, model) {
                      if (model.blocks.settings.homePageChat &&
                          widget.appStateModel.currentPageIndex == 0) {
                        return AccountFloatingButton(page: 'home');
                      } else {
                        return Container();
                      }
                    }),
                body: _children[widget.appStateModel.currentPageIndex],
                bottomNavigationBar: buildBottomNavigationBar(context),
              );
            } else {
              return Scaffold(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : model.blocks.settings.menuTheme.light.canvasColor,
                body: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle.dark,
                  child: Stack(
                    alignment: Alignment.center,
                    //mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          width: MediaQuery.of(context).size.width - 32,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 100,
                        child: Column(
                          children: [
                            Container(
                                width: 200,
                                child: Text(
                                  model.blocks.localeText.weAreNotInYourArea,
                                  textAlign: TextAlign.center, style: TextStyle(color: Colors.black),)),
                            SizedBox(
                              height: 12,
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => PlacePickerHome()));
                                setState(() {});
                                await model.updateAllBlocks();
                                setState(() {});
                              },
                              child: Text(model.blocks.localeText.changeYourLocation),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
      );
    }

    return Scaffold(
      drawerDragStartBehavior: DragStartBehavior.start,
      floatingActionButton: ScopedModelDescendant<AppStateModel>(
          builder: (context, child, model) {
            if (model.blocks.settings.homePageChat && widget.appStateModel.currentPageIndex == 0) {
              return AccountFloatingButton(page: 'home');
            } else {
              return Container();
            }
          }),
      body: _children[widget.appStateModel.currentPageIndex],
      bottomNavigationBar: buildBottomNavigationBar(context),
    );
  }

  onProductClick(product) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ProductDetail(product: product);
    }));
  }

  Future _openWhatsApp(String number) async {
    final url = 'https://wa.me/' + number;
    launchUrl(Uri.parse(url));
  }

  BottomNavigationBar? buildBottomNavigationBar(BuildContext context) {

    BottomNavigationBarModel bottomNavigationBar = widget.appStateModel.blocks.settings.bottomNavigationBar;

    if(bottomItemsLength >= 2 && bottomNavigationBar.items.length >= 2 && bottomItemsLength == bottomNavigationBar.items.length) {
      bool isDark = Theme.of(context).brightness == Brightness.dark;
      return BottomNavigationBar(
        currentIndex: widget.appStateModel.currentPageIndex,
        onTap: onChangePageIndex,
        type: bottomNavigationBar.type,
        //showSelectedLabels: bottomNavigationBar.showSelectedLabels,
        //showUnselectedLabels: bottomNavigationBar.showUnselectedLabels,
        items: setBottomNavigationBarItem(bottomNavigationBar.items),
        //elevation: bottomNavigationBar.elevation,
      );
    } return null;

  }

  setBottomNavigationBarItem(List<NavigationItem> items) {

    List<BottomNavigationBarItem> _bottomNavigationBarItem = [];

    if(bottomItemsLength == widget.appStateModel.blocks.settings.bottomNavigationBar.items.length)
      items.forEach((element) {
        if(element.link != 'cart') {
          _bottomNavigationBarItem.add(
              BottomNavigationBarItem(
                backgroundColor: element.backgroundColor,
                icon: DunesIcon(iconString: element.icon),
                activeIcon: DunesIcon(iconString: element.activeIcon),
                label: element.title,
              )
          );
        } else {
          _bottomNavigationBarItem.add(
              BottomNavigationBarItem(
                backgroundColor: element.backgroundColor,
                icon: Stack(children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                    child: DunesIcon(iconString: element.icon),
                  ),
                  new Positioned(
                    top: 0.0,
                    right: 0.0,
                    child: context.watch<ShoppingCart>().count != 0 ? Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: StadiumBorder(),
                        color: Colors.red,
                        child: Container(
                            padding: EdgeInsets.all(2),
                            constraints: BoxConstraints(minWidth: 20.0),
                            child: Center(
                                child: Text(
                                  context.read<ShoppingCart>().count.toString(),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      backgroundColor: Colors.red),
                                )))) : Container(),
                  ),
                ]),
                activeIcon: Stack(children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                    child: DunesIcon(iconString: element.activeIcon),
                  ),
                  new Positioned(
                    top: 0.0,
                    right: 0.0,
                    child: context.watch<ShoppingCart>().count != 0 ? Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: StadiumBorder(),
                        color: Colors.red,
                        child: Container(
                            padding: EdgeInsets.all(2),
                            constraints: BoxConstraints(minWidth: 20.0),
                            child: Center(
                                child: Text(
                                  context.read<ShoppingCart>().count.toString(),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      backgroundColor: Colors.red),
                                )))) : Container(),
                  ),
                ]),
                label: element.title,
              )
          );
        }
      });

    return _bottomNavigationBarItem;
  }

  Future<void> configureFcm() async {

    await Future.delayed(Duration(seconds: 3));

    try {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(announcement: true, criticalAlert: true);
    } catch(e) {}

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {_onMessage(message);});

    //FirebaseMessaging.onMessage.listen((RemoteMessage message) {_onMessage(message);});

    FirebaseMessaging.instance.getToken().then((String? token) {
      if(token != null) {
        widget.appStateModel.fcmToken = token;
        widget.appStateModel.apiProvider.post('/wp-admin/admin-ajax.php?action=build-app-online-update_user_notification', {'fcm_token': token});
      }
    });

    FirebaseMessaging.instance.subscribeToTopic('all');

  }

  void _onMessage(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      if (message.data.containsKey('category')) {
        var filter = new Map<String, dynamic>();
        filter['id'] = message.data['category'];
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ProductsWidget(filter: filter, name: '')));
      } else if (message.data.containsKey('product_id')) {
        Product product = Product.fromJson({'id': int.parse(message.data['product_id'].toString())});
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProductDetail(
                    product: product
                )));
      } else if (message.data.containsKey('product')) {
        Product product = Product.fromJson({'id': int.parse(message.data['product'].toString())});
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProductDetail(
                    product: product
                )));
      } else if (message.data.containsKey('page')) {
        var child = Child(linkId: message.data['page'].toString(), linkType: 'page');
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => WPPostPage(child: child)));
      } else if (message.data.containsKey('post')) {
        var child = Child(linkId: message.data['post'].toString(), linkType: 'post');
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => WPPostPage(child: child)));
      } else if (message.data.containsKey('link')) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    WebViewPage(url: message.data['link'], title: '')));
      } else if (message.data.containsKey('order')) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    OrderSummary(id: message.data['order'])));
      }
    } else if (message.data.containsKey('chat')) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  FireBaseChat(otherUserId: message.data['chat'])));
    }
  }

  void initDynamicLinks() {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
      await Future.delayed(Duration(seconds: 1));
      final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
      if(data != null) {
        final Uri? deepLink = data.link;
        if (deepLink != null) {
          this.navigateTo(deepLink);
        }
      } else {
        final Uri? deepLink = dynamicLinkData.link;
        if (deepLink != null) {
          this.navigateTo(deepLink);
        }
      }

    }).onError((error) {
      print('onLink error');
      print(error.message);
    });
  }

  Future<void> navigateTo(Uri deepLink) async {
    await Future.delayed(Duration(seconds: 1));
    if(deepLink.queryParameters.containsKey('wwref')) {
      ApiProvider().filter.addAll({'wwref': deepLink.queryParameters['wwref']!});
      ApiProvider().get('/my-account/?wwref=' + deepLink.queryParameters['wwref']!);
    }
    if (deepLink.queryParameters['category'] != null) {
      var filter = new Map<String, dynamic>();
      filter['id'] = deepLink.queryParameters['category'];
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProductsWidget(filter: filter, name: '')));
    } else if (deepLink.queryParameters.containsKey('product_id')) {
      Product product = Product.fromJson({'id': int.parse(deepLink.queryParameters['product_id']!)});
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProductDetail(
                  product: product
              )));
    } else if (deepLink.queryParameters.containsKey('product')) {
      Product product = Product.fromJson({'id': int.parse(deepLink.queryParameters['product']!)});
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProductDetail(
                  product: product
              )));
    } else if (deepLink.queryParameters.containsKey('page')) {
      var child = Child(linkId: deepLink.queryParameters['post'].toString(), linkType: 'page');
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => WPPostPage(child: child)));
    } else if (deepLink.queryParameters.containsKey('post')) {
      var child = Child(linkId: deepLink.queryParameters['post'].toString(), linkType: 'post');
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => WPPostPage(child: child)));
    } else if (deepLink.queryParameters.containsKey('link')) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  WebViewPage(url: deepLink.queryParameters['link']!, title: '')));
    } else if (deepLink.queryParameters.containsKey('order')) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  OrderSummary(id: deepLink.queryParameters['order']!)));
    } else if (deepLink.queryParameters.containsKey('chat')) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  FireBaseChat(otherUserId: deepLink.queryParameters['chat']!)));
    }
  }
}
