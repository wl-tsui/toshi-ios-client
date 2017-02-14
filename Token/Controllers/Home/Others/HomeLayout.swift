import UIKit

class HomeLayout: UICollectionViewFlowLayout {
    static let headerHeight = CGFloat(221)
    static let headerKind = "HeaderKind"
    static let itemHeight = CGFloat(90)
    static let itemWidth = CGFloat(70)
    static let verticalMargin = CGFloat(34)
    static let horizontalMargin = CGFloat(16)

    override init() {
        super.init()

        self.itemSize = CGSize(width: HomeLayout.itemWidth, height: HomeLayout.itemHeight)
        self.sectionInset = UIEdgeInsets(top: HomeLayout.verticalMargin, left: HomeLayout.horizontalMargin, bottom: HomeLayout.verticalMargin, right: HomeLayout.horizontalMargin)
        self.register(HomeHeaderView.self, forDecorationViewOfKind: HomeLayout.headerKind)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard var attributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }

        for attribute in attributes {
            var frame = attribute.frame
            frame.origin.y += HomeLayout.headerHeight
            attribute.frame = frame
        }

        let decorationAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: HomeLayout.headerKind, with: IndexPath(row: 0, section: 0))
        decorationAttributes.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: HomeLayout.headerHeight)

        attributes.append(decorationAttributes)

        return attributes
    }
}
