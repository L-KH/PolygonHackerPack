import { useEffect, useState } from 'react'
import { BiHeart } from 'react-icons/bi'
import { ethers } from 'ethers'

const style = {
  wrapper: `  flex-auto  my-10 mx-5 rounded-2xl overflow-hidden`,
  Container: `h-2/3 w-full overflow-hidden flex grid grid-cols-2 gap-4 place-content-start h-48`,
  details: `p-3`,
  info: ` flex justify-between text-[#e4e8eb] drop-shadow-xl`,
  infoLeft: `flex-0.6 flex-wrap`,
  assetName: `font-bold text-lg mt-2`,
  list: `font-bold text-lg text-[#142324]`,
  priceValue: `flex items-center text-xl font-bold mt-2`,
  button: `border border-[#8fa1b8] bg-[#2081e2] p-[0.8rem] text-xl font-semibold rounded-lg cursor-pointer text-black`,
}

const BoxCard = ({ boxnumber, box, winnerlist, claim }) => {
  function timeConverter(UNIX_timestamp) {
    if (UNIX_timestamp == 0) {
      return 0
    }
    var a = new Date(UNIX_timestamp * 1000);
    var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    var year = a.getFullYear();
    var month = months[a.getMonth()];
    var date = a.getDate();
    var hour = a.getHours();
    var min = a.getMinutes();
    var sec = a.getSeconds();
    var time = date + ' ' + month + ' ' + year + ' ' + hour + ':' + min + ':' + sec;
    return time;
  }

  return (
    <div
      className={style.wrapper}>

      <div className={style.details}>
        <div className="text-3xl px-10 py-4">Box: {boxnumber} </div>


        <div className={style.Container}>
          
            <div className={style.list}> winners
              {
                winnerlist?.map((partitipant, id) => (

                  <li className="text-sm text-black" key={id}> {partitipant.slice(0, 7) == 0x00000 ? (<a className="text-sm text-black">Claimed</a>) : (
                    <a className="text-sm text-black">{partitipant.slice(0, 7)} </a>
                  )
                  }</li>
                ))
              }
            </div>
          <div className={style.list}> Stakers
            {winnerlist?.length <= 6 ? (
              <div className="text-sm text-black">
                {
                  box.particip.map((partitipant, id) => (

                    <li key={id}> {partitipant.slice(0, 7)}...</li>


                  ))
                }
              </div>

            ) : (
              <div className={style.infoLeft}> Winners

                <div className={style.list}>
                  {
                    winnerlist.map((partitipant, id) => (

                      <li key={id}> {partitipant.slice(0, 7)}...</li>


                    ))
                  }
                </div>

              </div>

            )}
          </div>
        </div>
        <div className={style.assetName}> Distribution Start: {timeConverter(box.timeOfLastUpdate.toString())}</div>
        <div className={style.priceValue}>
          Reward : {ethers.utils.formatUnits(box.unclaimedRewards.toString(), 'ether')}
        </div>
      </div>
    </div>
  )
}

export default BoxCard