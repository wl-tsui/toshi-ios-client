// Copyright (c) 2017 Token Browser, Inc
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

import Foundation

extension String {
    public var isURL: Bool {
        let fullRange = NSRange(location: 0, length: self.length)
        let detector = try! NSDataDetector(types: NSTextCheckingAllSystemTypes)
        for match in detector.matches(in: self, options: [], range: fullRange) {
            if match.resultType == .link && match.range.location == fullRange.location && match.range.length == fullRange.length {
                return true
            }
        }

        return false
    }
}
