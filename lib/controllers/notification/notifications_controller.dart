import 'package:foap/helper/date_extension.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/helper/list_extension.dart';
import 'package:foap/model/follow_request.dart';
import '../../api_handler/apis/misc_api.dart';
import '../../model/data_wrapper.dart';
import '../../model/notification_modal.dart';

class NotificationController extends GetxController {
  List<NotificationModel> filteredNotifications = [];
  List<NotificationModel> allNotification = [];
  RxList<FollowRequestModel> followRequests = <FollowRequestModel>[].obs;

  RxList<SMNotificationType> selectedNotificationsTypes =
      <SMNotificationType>[].obs;

  RxMap<String, List<NotificationModel>> groupedNotifications =
      <String, List<NotificationModel>>{}.obs;

  DataWrapper followRequestDataWrapper = DataWrapper();
  RxInt unreadNotificationCount = 0.obs;

  void clearFollowRequests() {
    followRequests.clear();
    followRequestDataWrapper = DataWrapper();
  }

  void filterNotifications() {
    if (selectedNotificationsTypes.isNotEmpty) {
      filteredNotifications = allNotification
          .where((element) => selectedNotificationsTypes.contains(element.type))
          .toList();
    } else {
      filteredNotifications = allNotification;
    }
    filteredNotifications = filteredNotifications.map((e) {
      NotificationModel notification = e;
      if (e.date.isToday) {
        notification.notificationDate = todayString.tr;
      } else if (e.date.isThisWeek) {
        notification.notificationDate = thisWeekString.tr;
      } else if (e.date.isThisMonth) {
        notification.notificationDate = thisMonthString.tr;
      } else {
        notification.notificationDate = earlierString.tr;
      }
      return notification;
    }).toList();
    groupedNotifications.value =
        filteredNotifications.groupBy((m) => m.notificationDate);
    update();
  }

  void getNotifications() {
    MiscApi.getNotifications(resultCallback: (result, metadata) {
      allNotification = result;
      _syncUnreadCountFromLoadedNotifications();
      filterNotifications();
    });
  }

  void getNotificationInfo() {
    MiscApi.getNotificationInfo(resultCallback: (result) {
      unreadNotificationCount.value = result;
    });
  }

  Future<void> markNotificationAsRead(int id) async {
    final matched =
        allNotification.where((notification) => notification.id == id).toList();
    if (matched.isEmpty || matched.first.readStatus) return;

    final notification = matched.first;
    notification.readStatus = true;
    _syncUnreadCountFromLoadedNotifications();
    filterNotifications();

    final success = await MiscApi.markNotificationAsRead(id: id);
    if (success) {
      getNotificationInfo();
    } else {
      debugPrint(
          '[NotificationController] Failed to mark notification $id read');
    }
  }

  void markAllLoadedNotificationsAsRead() {
    final unreadIds = allNotification
        .where((notification) => !notification.readStatus)
        .map((notification) => notification.id)
        .toList();
    if (unreadIds.isEmpty) return;

    for (final notification in allNotification) {
      notification.readStatus = true;
    }
    _syncUnreadCountFromLoadedNotifications();
    filterNotifications();

    for (final id in unreadIds) {
      MiscApi.markNotificationAsRead(id: id);
    }
  }

  void _syncUnreadCountFromLoadedNotifications() {
    unreadNotificationCount.value = allNotification
        .where((notification) => !notification.readStatus)
        .length;
  }

  void selectNotificationType(SMNotificationType type) {
    if (selectedNotificationsTypes.contains(type)) {
      selectedNotificationsTypes.remove(type);
    } else {
      selectedNotificationsTypes.add(type);
    }
  }

  void refreshFollowRequests(VoidCallback callback) {
    clearFollowRequests();
    getFollowRequests(callback);
  }

  void loadMoreFollowRequests(VoidCallback callback) {
    if (followRequestDataWrapper.haveMoreData.value) {
      followRequestDataWrapper.page += 1;
      getFollowRequests(callback);
    } else {
      callback();
    }
  }

  void getFollowRequests(VoidCallback callback) {
    MiscApi.getFollowRequests(
        page: followRequestDataWrapper.page,
        resultCallback: (result, metadata) {
          followRequestDataWrapper.processCompletedWithData(metadata);
          followRequests.addAll(result);
          callback();
          update();
        });
  }

  void acceptFollowRequest(int userId) {
    followRequests.removeWhere((element) => element.sender.id == userId);
    update();

    MiscApi.acceptFollowRequest(userId: userId);
  }

  void delcineFollowRequest(int userId) {
    followRequests.removeWhere((element) => element.sender.id == userId);

    update();
    MiscApi.declineFollowRequest(userId: userId);
  }
}
