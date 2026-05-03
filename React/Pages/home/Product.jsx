import { useState } from "react";
import { formatMoney } from "../../src/utils/money";
import axios from "axios";  



export function Product({product, loadCart}) {

     const [quantity, setQuantity] = useState(1);
    return(
             <div  className="product-container">
                    <div className="product-image-container">
                      <img className="product-image"
                        src={product.image} />
                    </div>
        
                    <div className="product-name limit-text-to-2-lines">
                      Black and Gray Athletic Cotton Socks - 6 Pairs
                    </div>
        
                    <div className="product-rating-container">
                      <img className="product-rating-stars"
                        src={`images/ratings/rating-${product.rating.stars*10}.png`} />
                      <div className="product-rating-count link-primary">
                        {product.ratingCount}
                      </div>
                    </div>
        
                    <div className="product-price">
                      {formatMoney(product.priceCents)}
                    </div>
        
                    <div className="product-quantity-container">
                      <select value={quantity} onChange={(e) => {
                        const quantitySelected = Number(e.target.value);
                        setQuantity(quantitySelected);
                      }}>

              
                      
                        <option value="1">1</option>
                        <option value="2">2</option>
                        <option value="3">3</option>
                        <option value="4">4</option>
                        <option value="5">5</option>
                        <option value="6">6</option>
                        <option value="7">7</option>
                        <option value="8">8</option>
                        <option value="9">9</option>
                        <option value="10">10</option>
                      </select>
                    </div>
        
                    <div className="product-spacer"></div>
        
                    <div className="added-to-cart">
                      <img src="images/icons/checkmark.png" />
                      Added
                    </div>
        
                    <button className="add-to-cart-button button-primary"
                    onClick={async () => {
                      await axios.post('/api/cart-items', {
                        productId: product.id,
                        quantity: quantity
                      });
                      await loadCart();
                    }}>

                      Add to Cart
                    </button>
                  </div>
    );
}