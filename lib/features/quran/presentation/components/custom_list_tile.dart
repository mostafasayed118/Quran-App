import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';

class CustomListTile extends StatelessWidget {
  final String title;
  final Widget icon;

  final VoidCallback? onTap;

  const CustomListTile({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: AppColors.orangeColor,
              ),
        ),
        leading: icon,
        onTap: onTap);
  }
}
