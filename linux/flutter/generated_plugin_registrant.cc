//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_libserialport/flutter_libserialport_plugin.h>
#include <open_file_linux/open_file_linux_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flutter_libserialport_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterLibserialportPlugin");
  flutter_libserialport_plugin_register_with_registrar(flutter_libserialport_registrar);
  g_autoptr(FlPluginRegistrar) open_file_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "OpenFileLinuxPlugin");
  open_file_linux_plugin_register_with_registrar(open_file_linux_registrar);
}
