import 'package:flutter/material.dart';

class BottomNavBarItem {
  final String title;
  final IconData icon;
  BottomNavBarItem({
    required this.title,
    required this.icon,
  });
}

class BottomNavBar extends StatefulWidget {
  final List<BottomNavBarItem> children;
  int curentIndex;
  final Color? backgroundColor;
  Function(int)? onTap;
  BottomNavBar(
      {super.key,
        required this.children,
        required this.curentIndex,
        this.backgroundColor,
        required this.onTap});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
      ),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),

      height: 56,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          widget.children.length,
              (index) => NavBarItem(
            index: index,
            item: widget.children[index],
            selected: widget.curentIndex == index,
            onTap: () {
              setState(() {
                widget.curentIndex = index;
                widget.onTap!(widget.curentIndex);
              });
            },
          ),
        ),
      ),
    );
  }
}

class NavBarItem extends StatefulWidget {
  final BottomNavBarItem item;
  final int index;
  bool selected;
  final Function onTap;
  final Color? backgroundColor;
  NavBarItem({
    super.key,
    required this.item,
    this.selected = false,
    required this.onTap,
    this.backgroundColor,
    required this.index,
  });

  @override
  State<NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<NavBarItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
      },
      child: AnimatedContainer(
        margin: const EdgeInsets.all(8),
        duration: const Duration(milliseconds: 300),
        constraints: BoxConstraints(minWidth: widget.selected ? 120 : 56),
        height: 60,
        decoration: BoxDecoration(
          color: widget.selected
              ? widget.backgroundColor ?? Color(0xFF83C2D9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.item.icon,
              color: widget.selected ? Colors.white : Colors.grey,
            ),
            Offstage(
                offstage: !widget.selected, child: Text(widget.item.title, style: TextStyle(color: Colors.white),)),
          ],
        ),
      ),
    );
  }
}

