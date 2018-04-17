// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/*
 Generally ganked from https://gist.github.com/Sorix/1d8543b18cfd76c12c36525bc280a35d

 Workaround for the fact that when you pop a view controller non-interactively, the colors,
 especially the title color, do not render correctly after the pop.

 Will add Radar here once filed.
 */

protocol NavBarColorChanging: class {

    var navTintColor: UIColor? { get }
    var navBarTintColor: UIColor? { get }
    var navTitleColor: UIColor? { get }
    var navShadowImage: UIImage? { get }
}
