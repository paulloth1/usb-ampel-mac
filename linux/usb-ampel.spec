%{!?ver: %global ver 0.0.0}

Name:           usb-ampel
Version:        %{ver}
Release:        1%{?dist}
Summary:        Control a Cleware USB-Ampel traffic light
License:        MIT
URL:            https://github.com/paulloth1/usb-ampel-mac
BuildArch:      noarch

BuildRequires:  desktop-file-utils
BuildRequires:  systemd-rpm-macros
Requires:       python3
Requires:       python3-gobject
Requires:       python3-cairo
Requires:       gtk4
Requires:       libadwaita
Requires:       hicolor-icon-theme

%description
GTK4/libadwaita app and command line tool to control a Cleware USB-Ampel
(USB ID 0d50:0008). Includes a udev rule so the desktop user can use the
light without root.

%prep

%build

%install
install -Dm755 %{_sourcedir}/usb-ampel %{buildroot}%{_bindir}/usb-ampel
sed -i 's/@VERSION@/%{version}/' %{buildroot}%{_bindir}/usb-ampel
install -Dm644 %{_sourcedir}/70-cleware-ampel.rules %{buildroot}%{_udevrulesdir}/70-cleware-ampel.rules
install -Dm644 %{_sourcedir}/de.paulloth.UsbAmpel.desktop %{buildroot}%{_datadir}/applications/de.paulloth.UsbAmpel.desktop
install -Dm644 %{_sourcedir}/de.paulloth.UsbAmpel.png %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/de.paulloth.UsbAmpel.png

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/de.paulloth.UsbAmpel.desktop

%post
udevadm control --reload-rules >/dev/null 2>&1 || :
udevadm trigger --subsystem-match=hidraw >/dev/null 2>&1 || :

%postun
udevadm control --reload-rules >/dev/null 2>&1 || :

%files
%{_bindir}/usb-ampel
%{_udevrulesdir}/70-cleware-ampel.rules
%{_datadir}/applications/de.paulloth.UsbAmpel.desktop
%{_datadir}/icons/hicolor/256x256/apps/de.paulloth.UsbAmpel.png

%changelog
* Fri Nov 06 2026 Paul <paulloth2208@gmail.com> - 1.1.0-1
- Linux GTK4 app and CLI
