import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/controllers/activity.dart';
import 'package:otraku/utils/config.dart';
import 'package:otraku/enums/activity_type.dart';
import 'package:otraku/enums/browsable.dart';
import 'package:otraku/enums/themes.dart';
import 'package:otraku/models/activity_model.dart';
import 'package:otraku/pages/activity_page.dart';
import 'package:otraku/widgets/browse_indexer.dart';
import 'package:otraku/widgets/fade_image.dart';
import 'package:otraku/widgets/html_content.dart';
import 'package:otraku/widgets/triangle_clip.dart';

class UserActivity extends StatelessWidget {
  final ActivityModel activity;

  UserActivity(this.activity);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BrowseIndexer(
              id: activity.agentId!,
              imageUrl: activity.agentImage,
              browsable: Browsable.user,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: Config.BORDER_RADIUS,
                    child: FadeImage(
                      activity.agentImage,
                      height: 50,
                      width: 50,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    activity.agentName!,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ],
              ),
            ),
            if (activity.recieverId != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_right_alt),
              ),
              BrowseIndexer(
                id: activity.recieverId!,
                imageUrl: activity.recieverImage,
                browsable: Browsable.user,
                child: ClipRRect(
                  borderRadius: Config.BORDER_RADIUS,
                  child: FadeImage(
                    activity.recieverImage,
                    height: 50,
                    width: 50,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        ClipPath(
          clipper: TriangleClip(),
          child: Container(
            width: 50,
            height: 10,
            color: Theme.of(context).primaryColor,
          ),
        ),
        ActivityBox(activity),
      ],
    );
  }
}

class ActivityBox extends StatefulWidget {
  final ActivityModel activity;
  final bool canPush;

  ActivityBox(this.activity, {this.canPush = true});

  @override
  _ActivityBoxState createState() => _ActivityBoxState();
}

class _ActivityBoxState extends State<ActivityBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: Config.PADDING,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: Config.BORDER_RADIUS,
      ),
      child: Column(
        children: [
          if (widget.activity.type == ActivityType.ANIME_LIST ||
              widget.activity.type == ActivityType.MANGA_LIST)
            BrowseIndexer(
              id: widget.activity.mediaId!,
              imageUrl: widget.activity.mediaImage,
              browsable: widget.activity.mediaType!,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 108),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: Config.BORDER_RADIUS,
                      child: FadeImage(
                        widget.activity.mediaImage,
                        width: 70,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: Config.PADDING,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: RichText(
                                overflow: TextOverflow.fade,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: widget.activity.text,
                                      style:
                                          Theme.of(context).textTheme.bodyText1,
                                    ),
                                    TextSpan(
                                      text: widget.activity.mediaTitle,
                                      style:
                                          Theme.of(context).textTheme.bodyText2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.activity.mediaFormat != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  widget.activity.mediaFormat!,
                                  style: Theme.of(context).textTheme.bodyText1,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            UnconstrainedBox(
              constrainedAxis: Axis.horizontal,
              alignment: Alignment.topLeft,
              child: HtmlContent(widget.activity.text),
            ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.activity.createdAt,
                style: Theme.of(context).textTheme.subtitle2,
              ),
              Row(
                children: [
                  _SubscribeIcon(widget.activity),
                  const SizedBox(width: 10),
                  Tooltip(
                    message: 'Replies',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (widget.canPush)
                          Get.toNamed(
                            ActivityPage.ROUTE,
                            arguments: [
                              widget.activity.id,
                              widget.activity,
                              (ActivityModel other) => setState(
                                    () => widget.activity.updateFrom(other),
                                  ),
                            ],
                            parameters: {'id': widget.activity.id.toString()},
                          );
                      },
                      child: Row(
                        children: [
                          Text(
                            widget.activity.replyCount.toString(),
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Ionicons.chatbox,
                            size: Style.ICON_SMALL,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ActivityLikeIcon(widget.activity),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityLikeIcon extends StatefulWidget {
  final ActivityModel activity;
  _ActivityLikeIcon(this.activity);

  @override
  _ActivityLikeIconState createState() => _ActivityLikeIconState();
}

class _ActivityLikeIconState extends State<_ActivityLikeIcon> {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: !widget.activity.isLiked ? 'Like' : 'Unlike',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Activity.toggleActivityLike(widget.activity)
            .then((_) => setState(() {})),
        child: Row(
          children: [
            Text(
              widget.activity.likeCount.toString(),
              style: !widget.activity.isLiked
                  ? Theme.of(context).textTheme.subtitle2
                  : Theme.of(context)
                      .textTheme
                      .subtitle2!
                      .copyWith(color: Theme.of(context).errorColor),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.favorite,
              size: Style.ICON_SMALL,
              color:
                  widget.activity.isLiked ? Theme.of(context).errorColor : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscribeIcon extends StatefulWidget {
  final ActivityModel activity;
  _SubscribeIcon(this.activity);

  @override
  _SubscribeIconState createState() => _SubscribeIconState();
}

class _SubscribeIconState extends State<_SubscribeIcon> {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: !widget.activity.isSubscribed ? 'Subscribe' : 'Unsubscribe',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Activity.toggleSubscription(widget.activity)
            .then((_) => setState(() {})),
        child: Icon(
          Ionicons.notifications,
          size: Style.ICON_SMALL,
          color: !widget.activity.isSubscribed
              ? null
              : Theme.of(context).accentColor,
        ),
      ),
    );
  }
}
