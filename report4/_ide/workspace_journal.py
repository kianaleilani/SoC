# 2025-11-12T22:22:00.472196700
import vitis

client = vitis.create_client()
client.set_workspace(path="report4")

advanced_options = client.create_advanced_options_dict(dt_overlay="0")

platform = client.create_platform_component(name = "platform",hw_design = "$COMPONENT_LOCATION/../mcs_top_report4.xsa",os = "standalone",cpu = "microblaze_I",domain_name = "standalone_microblaze_I",generate_dtb = False,advanced_options = advanced_options,compiler = "gcc")

comp = client.create_app_component(name="app_component",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_I")

comp = client.get_component(name="app_component")
status = comp.import_files(from_loc="$COMPONENT_LOCATION/../../fpga_mcs_sv_src/cpp/drv", files=["chu_init.cpp", "chu_init.h", "chu_io_map.h", "chu_io_rw.h", "gpio_cores.cpp", "gpio_cores.h", "spi_core.cpp", "spi_core.h", "timer_core.cpp", "timer_core.h", "uart_core.cpp", "uart_core.h"], dest_dir_in_cmp = "app_component")

status = comp.import_files(from_loc="$COMPONENT_LOCATION/../../fpga_mcs_sv_src/cpp/app", files=["main_vanilla_test.cpp"], dest_dir_in_cmp = "app_component")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()

